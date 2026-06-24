-- =================================================================
-- COMPREHENSIVE QUERY-LEVEL COMPARISON - AB TEST VERSION
-- Compares Control vs Treatment at query level using Eppo assignments
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
  WHERE assignment_date <= end_date  -- Assigned by end date
    AND variation IN ('A', 'B')  -- A=Control, B=Treatment; exclude C=Non-participants
),

events AS (
  SELECT
    DATE(eventTimestamp) AS partition_date,
    eventTimestamp,
    globalEntityId       AS global_entity_id,
    clientId             AS client_id,
    sessionId            AS session_key,
    JSON_VALUE(eventVariablesJson, '$.searchTrackingId') AS search_request_id,
    eventAction AS event_name,
    SAFE_CAST(JSON_VALUE(eventVariablesJson, '$.shopQuantityTotal') AS INT64) AS shop_quantity_total,
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
  WHERE e.eventTimestamp >= a.assignment_timestamp  -- Only events after assignment
),

-- Get correct shop positions from shop_list.updated + shop_list.expanded baseline
shop_positions AS (
  SELECT
    search_request_id,
    shop_id,
    -- Use cumulative count of actual shops per page (not hardcoded 25)
    -- Add +1 for 1-based ranking (position 1 = first result)
    -- MIN handles rare duplicate shops in BAEMIN_DELIVERY (0.8% of cases)
    MIN(page_offset + position + 1) AS correct_position
  FROM (
    SELECT
      search_request_id,
      shops_ids,
      -- Calculate cumulative count of shops from all previous pages
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

-- Get clicked shops with corrected positions
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

search_grain AS (
  SELECT
    assigned_events.partition_date,
    assigned_events.variation,
    assigned_events.global_entity_id,
    assigned_events.search_request_id,
    ANY_VALUE(assigned_events.session_key) AS session_key,
    ANY_VALUE(assigned_events.search_term) AS search_term,
    MAX(IF(assigned_events.event_name='shop_list.updated', assigned_events.search_vertical, NULL)) AS search_vertical,
    MAX(IF(assigned_events.event_name='shop_list.updated', assigned_events.shop_quantity_total, NULL)) AS shop_quantity_total,
    COUNTIF(assigned_events.event_name='shop.clicked') > 0 AS had_click,
    COUNTIF(assigned_events.event_name='transaction') > 0 AS had_order,
    -- Click rank using CORRECTED positions from shop_list.updated
    (SELECT MIN(correct_position) FROM clicks_with_positions cwp WHERE cwp.search_request_id = assigned_events.search_request_id) AS first_click_rank
  FROM assigned_events
  WHERE assigned_events.search_request_id IS NOT NULL
  GROUP BY 1, 2, 3, 4
),

-- ===== QUERY-LEVEL METRICS BY VARIATION =====
query_metrics AS (
  SELECT
    variation,
    search_vertical,
    search_term,

    COUNT(*) AS searches,
    COUNT(DISTINCT session_key) AS unique_sessions,
    COUNTIF(had_click) AS clicks,
    COUNTIF(had_order) AS orders,
    COUNTIF(shop_quantity_total = 0) AS zero_results,

    ROUND(SAFE_DIVIDE(COUNTIF(had_click), COUNT(*)), 4) AS ctr,
    ROUND(SAFE_DIVIDE(COUNTIF(had_order), COUNT(*)), 4) AS cvr,
    ROUND(SAFE_DIVIDE(COUNTIF(shop_quantity_total = 0), COUNT(*)), 4) AS zrr,
    ROUND(AVG(first_click_rank), 2) AS avg_click_rank,
    ROUND(AVG(shop_quantity_total), 2) AS avg_results_returned

  FROM search_grain
  WHERE search_term IS NOT NULL
    AND search_vertical IN ('ALL', 'BAEMIN_DELIVERY')  -- Exclude NULL vertical
  GROUP BY 1, 2, 3
),

-- ===== QUERY COMPARISON: CONTROL VS TREATMENT =====
query_comparison AS (
  SELECT
    COALESCE(control.search_vertical, treatment.search_vertical, 'NULL_VERTICAL') AS search_vertical,
    COALESCE(control.search_term, treatment.search_term) AS search_query,

    -- Control metrics
    control.searches AS control_searches,
    control.unique_sessions AS control_sessions,
    control.clicks AS control_clicks,
    control.orders AS control_orders,
    control.zero_results AS control_zero_results,
    control.ctr AS control_ctr,
    control.cvr AS control_cvr,
    control.zrr AS control_zrr,
    control.avg_click_rank AS control_avg_click_rank,
    control.avg_results_returned AS control_avg_results,

    -- Treatment metrics
    treatment.searches AS treatment_searches,
    treatment.unique_sessions AS treatment_sessions,
    treatment.clicks AS treatment_clicks,
    treatment.orders AS treatment_orders,
    treatment.zero_results AS treatment_zero_results,
    treatment.ctr AS treatment_ctr,
    treatment.cvr AS treatment_cvr,
    treatment.zrr AS treatment_zrr,
    treatment.avg_click_rank AS treatment_avg_click_rank,
    treatment.avg_results_returned AS treatment_avg_results,

    -- Absolute differences
    treatment.ctr - control.ctr AS ctr_absolute_diff,
    treatment.cvr - control.cvr AS cvr_absolute_diff,
    treatment.zrr - control.zrr AS zrr_absolute_diff,

    -- Percentage changes
    ROUND(SAFE_DIVIDE(treatment.ctr - control.ctr, NULLIF(control.ctr, 0)) * 100, 2) AS ctr_pct_change,
    ROUND(SAFE_DIVIDE(treatment.cvr - control.cvr, NULLIF(control.cvr, 0)) * 100, 2) AS cvr_pct_change,
    ROUND(SAFE_DIVIDE(treatment.zrr - control.zrr, NULLIF(control.zrr, 0)) * 100, 2) AS zrr_pct_change,

    -- Statistical significance for CTR
    CASE
      WHEN COALESCE(control.searches, 0) < 30 OR COALESCE(treatment.searches, 0) < 30 THEN 'Insufficient Data'
      WHEN control.ctr IS NULL OR treatment.ctr IS NULL THEN 'N/A'
      WHEN control.ctr = 0 AND treatment.ctr = 0 THEN 'No Clicks'
      WHEN ABS(
        (treatment.ctr - control.ctr) /
        NULLIF(SQRT(
          ((control.clicks + treatment.clicks) / (control.searches + treatment.searches)) *
          (1 - (control.clicks + treatment.clicks) / (control.searches + treatment.searches)) *
          (1.0/control.searches + 1.0/treatment.searches)
        ), 0)
      ) > 1.96 THEN 'Yes'
      ELSE 'No'
    END AS ctr_stat_sig,

    -- Statistical significance for CVR
    CASE
      WHEN COALESCE(control.searches, 0) < 30 OR COALESCE(treatment.searches, 0) < 30 THEN 'Insufficient Data'
      WHEN control.cvr IS NULL OR treatment.cvr IS NULL THEN 'N/A'
      WHEN control.cvr = 0 AND treatment.cvr = 0 THEN 'No Orders'
      WHEN ABS(
        (treatment.cvr - control.cvr) /
        NULLIF(SQRT(
          ((control.orders + treatment.orders) / (control.searches + treatment.searches)) *
          (1 - (control.orders + treatment.orders) / (control.searches + treatment.searches)) *
          (1.0/control.searches + 1.0/treatment.searches)
        ), 0)
      ) > 1.96 THEN 'Yes'
      ELSE 'No'
    END AS cvr_stat_sig

  FROM (SELECT * FROM query_metrics WHERE variation = 'A') control
  FULL OUTER JOIN (SELECT * FROM query_metrics WHERE variation = 'B') treatment
    ON COALESCE(control.search_vertical, 'NULL_VERTICAL') = COALESCE(treatment.search_vertical, 'NULL_VERTICAL')
    AND control.search_term = treatment.search_term
  WHERE treatment.searches >= 5  -- Only queries with meaningful Treatment volume
)

-- Final output
SELECT
  CONCAT(FORMAT_DATE('%Y-%m-%d', start_date), ' to ', FORMAT_DATE('%Y-%m-%d', end_date)) AS date_range,
  search_vertical,
  search_query,

  -- Volume metrics
  control_searches,
  treatment_searches,

  -- Core rates (easier to compare side-by-side)
  control_ctr,
  treatment_ctr,
  control_cvr,
  treatment_cvr,

  -- Key changes (what you look at first)
  ctr_pct_change,
  cvr_pct_change,
  ctr_stat_sig,
  cvr_stat_sig,

  -- Click position
  control_avg_click_rank,
  treatment_avg_click_rank,

  -- Additional metrics
  control_zrr,
  treatment_zrr,
  zrr_pct_change,

  -- Traffic split validation
  ROUND(SAFE_DIVIDE(treatment_searches, control_searches + treatment_searches) * 100, 1) AS treatment_traffic_pct

FROM query_comparison
ORDER BY
  COALESCE(treatment_searches, 0) + COALESCE(control_searches, 0) DESC,
  search_vertical,
  search_query;
