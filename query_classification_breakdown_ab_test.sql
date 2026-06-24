-- =================================================================
-- QUERY CLASSIFICATION BREAKDOWN - AB TEST
-- Analyzes Control vs Treatment by Vertical × Tier × Query Classification
-- Date range: May 30 - June 17, 2026 (inclusive)
-- =================================================================
DECLARE start_date DATE DEFAULT '2026-05-30';  -- AB test start date
DECLARE end_date DATE DEFAULT '2026-06-17';    -- AB test end date (inclusive)
-- =================================================================

WITH assignments AS (
  SELECT
    assignment_user_id AS client_id,
    variation,
    assignment_timestamp,
    assignment_date,
    global_entity_id
  FROM `dhub-gd-analytics.eppo_input.gs_woowa_assignments`
  WHERE assignment_date <= end_date
    AND variation IN ('A', 'B')  -- A=Control, B=Treatment
),

events AS (
  SELECT
    DATE(eventTimestamp) AS partition_date,
    eventTimestamp,
    globalEntityId AS global_entity_id,
    clientId AS client_id,
    sessionId AS session_key,
    JSON_VALUE(eventVariablesJson, '$.searchTrackingId') AS search_request_id,
    eventAction AS event_name,
    JSON_VALUE(eventVariablesJson, '$.searchVerticalName') AS search_vertical,
    JSON_VALUE(eventVariablesJson, '$.searchTerm') AS search_term,
    JSON_VALUE(eventVariablesJson, '$.shopsIds') AS shops_ids,
    JSON_VALUE(eventVariablesJson, '$.shopId') AS shop_id
  FROM `fulfillment-dwh-production.curated_data_shared_data_stream_perseus.baemin_korea_perseus`
  WHERE DATE(eventTimestamp) BETWEEN start_date AND end_date
    AND eventAction IN ('shop_list.updated','shop.clicked','shop_list.expanded','transaction')
    AND clientId IS NOT NULL
),

-- Join events with assignments
assigned_events AS (
  SELECT
    e.*,
    a.variation,
    a.assignment_timestamp
  FROM events e
  INNER JOIN assignments a
    ON e.client_id = a.client_id
  WHERE e.eventTimestamp >= a.assignment_timestamp
),

-- Get correct shop positions
shop_positions AS (
  SELECT
    search_request_id,
    shop_id,
    MIN(page_offset + position + 1) AS correct_position
  FROM (
    SELECT
      search_request_id,
      shops_ids,
      COALESCE(
        SUM(ARRAY_LENGTH(SPLIT(shops_ids, ',')))
          OVER (PARTITION BY search_request_id ORDER BY eventTimestamp
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),
        0
      ) AS page_offset
    FROM assigned_events
    WHERE event_name IN ('shop_list.updated', 'shop_list.expanded')
      AND shops_ids IS NOT NULL
  ),
  UNNEST(SPLIT(shops_ids, ',')) AS shop_id WITH OFFSET AS position
  GROUP BY search_request_id, shop_id
),

clicks_with_positions AS (
  SELECT
    e.partition_date,
    e.variation,
    e.global_entity_id,
    e.session_key,
    e.search_request_id,
    sp.correct_position
  FROM assigned_events e
  INNER JOIN shop_positions sp
    ON e.search_request_id = sp.search_request_id
    AND e.shop_id = sp.shop_id
  WHERE e.event_name = 'shop.clicked'
),

-- Aggregate at search grain
search_grain AS (
  SELECT
    events.partition_date,
    events.variation,
    events.global_entity_id,
    events.search_request_id,
    ANY_VALUE(events.session_key) AS session_key,
    ANY_VALUE(events.search_term) AS search_term,
    MAX(IF(events.event_name='shop_list.updated', events.search_vertical, NULL)) AS search_vertical,
    COUNTIF(events.event_name='shop.clicked') > 0 AS had_click,
    COUNTIF(events.event_name='transaction') > 0 AS had_order,
    (SELECT AVG(correct_position) FROM clicks_with_positions cwp 
     WHERE cwp.search_request_id = events.search_request_id) AS avg_click_rank,
    (SELECT MIN(correct_position) FROM clicks_with_positions cwp 
     WHERE cwp.search_request_id = events.search_request_id) AS first_click_rank
  FROM assigned_events events
  WHERE events.search_request_id IS NOT NULL
  GROUP BY 1, 2, 3, 4
),

-- Get query classifications from backend tracking (Treatment only has this)
query_classifications AS (
  SELECT DISTINCT
    request.query AS search_term,
    query_expansion.response.query_classification AS classification
  FROM `search-restaurant-stats-9826.backendtracking.vendor-v1`
  WHERE DATE(timestamp_utc) BETWEEN start_date AND end_date
    AND request.brand = 'baemin'
    AND request.query IS NOT NULL
    AND query_expansion.response.query_classification IS NOT NULL
),

-- Calculate tiers based on combined volume (A + B)
combined_search_volume AS (
  SELECT
    search_vertical,
    search_term,
    COUNT(*) AS total_searches_combined,
    SUM(COUNT(*)) OVER (
      PARTITION BY search_vertical
      ORDER BY COUNT(*) DESC
    ) AS cumulative_searches
  FROM search_grain
  WHERE search_term IS NOT NULL
    AND search_vertical IN ('ALL', 'BAEMIN_DELIVERY')
  GROUP BY search_vertical, search_term
),

tier_calculation AS (
  SELECT
    search_vertical,
    search_term,
    total_searches_combined,
    cumulative_searches,
    ROUND(cumulative_searches / SUM(total_searches_combined) 
      OVER (PARTITION BY search_vertical), 4) AS cumulative_pct,
    CASE
      WHEN cumulative_searches / SUM(total_searches_combined) 
        OVER (PARTITION BY search_vertical) <= 0.50 THEN 'Head'
      WHEN cumulative_searches / SUM(total_searches_combined) 
        OVER (PARTITION BY search_vertical) <= 0.80 THEN 'Torso'
      ELSE 'Tail'
    END AS tier
  FROM combined_search_volume
),

-- Aggregate by vertical, tier, classification, variation
aggregated_metrics AS (
  SELECT
    sg.search_vertical,
    tc.tier,
    COALESCE(qc.classification, 'unclassified') AS classification,
    sg.variation,
    COUNT(DISTINCT sg.search_request_id) AS searches,
    COUNTIF(sg.had_click) AS searches_with_click,
    COUNTIF(sg.had_order) AS searches_with_order,
    SAFE_DIVIDE(COUNTIF(sg.had_click), COUNT(DISTINCT sg.search_request_id)) AS ctr,
    SAFE_DIVIDE(COUNTIF(sg.had_order), COUNT(DISTINCT sg.search_request_id)) AS cvr,
    ROUND(AVG(sg.avg_click_rank), 2) AS avg_click_rank,
    COUNTIF(sg.first_click_rank = 1) AS clicks_position_1,
    COUNTIF(sg.first_click_rank BETWEEN 2 AND 3) AS clicks_position_2_3,
    COUNTIF(sg.first_click_rank BETWEEN 4 AND 10) AS clicks_position_4_10
  FROM search_grain sg
  INNER JOIN tier_calculation tc
    ON sg.search_vertical = tc.search_vertical
    AND sg.search_term = tc.search_term
  LEFT JOIN query_classifications qc
    ON sg.search_term = qc.search_term
  WHERE sg.search_vertical IN ('ALL', 'BAEMIN_DELIVERY')
  GROUP BY 1, 2, 3, 4
)

-- Pivot Control vs Treatment
SELECT
  search_vertical,
  tier,
  classification,
  
  -- Control (A) metrics
  control.searches AS control_searches,
  ROUND(control.ctr, 4) AS control_ctr,
  ROUND(control.cvr, 4) AS control_cvr,
  control.avg_click_rank AS control_avg_click_rank,
  control.clicks_position_1 AS control_clicks_pos_1,
  
  -- Treatment (B) metrics
  treatment.searches AS treatment_searches,
  ROUND(treatment.ctr, 4) AS treatment_ctr,
  ROUND(treatment.cvr, 4) AS treatment_cvr,
  treatment.avg_click_rank AS treatment_avg_click_rank,
  treatment.clicks_position_1 AS treatment_clicks_pos_1,
  
  -- Deltas
  ROUND(100.0 * (treatment.ctr - control.ctr) / NULLIF(control.ctr, 0), 2) AS ctr_pct_change,
  ROUND(100.0 * (treatment.cvr - control.cvr) / NULLIF(control.cvr, 0), 2) AS cvr_pct_change,
  ROUND(treatment.avg_click_rank - control.avg_click_rank, 2) AS avg_click_rank_diff,
  
  -- Statistical significance (simplified Z-test for CTR)
  CASE
    WHEN control.searches < 30 OR treatment.searches < 30 THEN 'Insufficient Data'
    WHEN ABS(treatment.ctr - control.ctr) / SQRT(
      (control.ctr * (1 - control.ctr) / control.searches) +
      (treatment.ctr * (1 - treatment.ctr) / treatment.searches)
    ) > 1.96 THEN 'Yes'
    ELSE 'No'
  END AS ctr_significant

FROM (
  SELECT * FROM aggregated_metrics WHERE variation = 'A'
) control
FULL OUTER JOIN (
  SELECT * FROM aggregated_metrics WHERE variation = 'B'
) treatment
  ON control.search_vertical = treatment.search_vertical
  AND control.tier = treatment.tier
  AND control.classification = treatment.classification

ORDER BY 
  search_vertical,
  CASE tier 
    WHEN 'Head' THEN 1 
    WHEN 'Torso' THEN 2 
    WHEN 'Tail' THEN 3 
  END,
  classification,
  control_searches DESC;
