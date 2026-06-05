-- =================================================================
-- HEAD/TORSO/TAIL COMPARISON - AB TEST VERSION
-- Compares Control vs Treatment by query frequency tier using Eppo assignments
-- Unified tiers based on combined (Control + Treatment) volume
-- Uses YESTERDAY's data (D+1 lag for assignments)
-- =================================================================
DECLARE report_date DATE DEFAULT CURRENT_DATE() - 1;  -- Yesterday (D+1 lag)
-- =================================================================

WITH assignments AS (
  SELECT
    assignment_user_id AS client_id,
    variation,
    assignment_timestamp,
    assignment_date,
    global_entity_id
  FROM `dhub-gd-analytics.eppo_input.gs_woowa_assignments`
  WHERE assignment_date <= report_date  -- Assigned by yesterday
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
  WHERE DATE(eventTimestamp) = report_date
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

-- Get correct shop positions from shop_list.updated baseline
shop_positions AS (
  SELECT
    search_request_id,
    shop_id,
    position as correct_position
  FROM assigned_events,
  UNNEST(SPLIT(shops_ids, ',')) as shop_id WITH OFFSET as position
  WHERE event_name = 'shop_list.updated'
    AND shops_ids IS NOT NULL
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
    COUNTIF(assigned_events.event_name='shop_list.expanded') > 0 AS had_pagination,
    -- Click rank using CORRECTED positions from shop_list.updated
    (SELECT MIN(correct_position) FROM clicks_with_positions cwp WHERE cwp.search_request_id = assigned_events.search_request_id) AS first_click_rank
  FROM assigned_events
  WHERE assigned_events.search_request_id IS NOT NULL
  GROUP BY 1, 2, 3, 4
),

-- ===== TIER CALCULATION (UNIFIED - based on combined Control + Treatment volume) =====
combined_search_volume AS (
  SELECT
    search_vertical,
    search_term,
    COUNT(*) AS total_searches_combined,  -- Total across both variations
    SUM(COUNT(*)) OVER (
      PARTITION BY search_vertical  -- Only by vertical, NOT by variation
      ORDER BY COUNT(*) DESC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_searches
  FROM search_grain
  WHERE search_term IS NOT NULL
    AND search_vertical IN ('ALL', 'BAEMIN_DELIVERY')  -- Exclude NULL vertical
  GROUP BY search_vertical, search_term
),

tier_calculation AS (
  SELECT
    search_vertical,
    search_term,
    total_searches_combined,
    cumulative_searches,
    ROUND(cumulative_searches / SUM(total_searches_combined) OVER (PARTITION BY search_vertical), 4) AS cumulative_pct,
    CASE
      WHEN cumulative_searches / SUM(total_searches_combined) OVER (PARTITION BY search_vertical) <= 0.50 THEN 'Head'
      WHEN cumulative_searches / SUM(total_searches_combined) OVER (PARTITION BY search_vertical) <= 0.80 THEN 'Torso'
      ELSE 'Tail'
    END AS tier
  FROM combined_search_volume
),

-- ===== QUERY-LEVEL METRICS BY VARIATION =====
query_metrics AS (
  SELECT
    variation,
    sg.search_vertical,
    sg.search_term,
    tier.tier AS frequency_tier,

    COUNT(*) AS searches,
    COUNTIF(had_click) AS clicks,
    COUNTIF(had_order) AS orders,
    COUNTIF(shop_quantity_total = 0) AS zero_results,

    ROUND(SAFE_DIVIDE(COUNTIF(had_click), COUNT(*)), 4) AS ctr,
    ROUND(SAFE_DIVIDE(COUNTIF(had_order), COUNT(*)), 4) AS cvr,
    ROUND(SAFE_DIVIDE(COUNTIF(shop_quantity_total = 0), COUNT(*)), 4) AS zrr,
    ROUND(AVG(first_click_rank), 2) AS avg_click_rank

  FROM search_grain sg
  INNER JOIN tier_calculation tier
    ON sg.search_term = tier.search_term
    AND sg.search_vertical = tier.search_vertical
  WHERE sg.search_term IS NOT NULL
    AND sg.search_vertical IN ('ALL', 'BAEMIN_DELIVERY')  -- Exclude NULL vertical
  GROUP BY 1, 2, 3, 4
),

-- ===== AGGREGATE BY TIER AND VARIATION =====
tier_aggregates AS (
  SELECT
    variation,
    search_vertical,
    frequency_tier,

    COUNT(DISTINCT search_term) AS unique_queries,
    SUM(searches) AS total_searches,
    SUM(clicks) AS total_clicks,
    SUM(orders) AS total_orders,
    SUM(zero_results) AS total_zero_results,

    ROUND(SAFE_DIVIDE(SUM(clicks), SUM(searches)), 4) AS ctr,
    ROUND(SAFE_DIVIDE(SUM(orders), SUM(searches)), 4) AS cvr,
    ROUND(SAFE_DIVIDE(SUM(zero_results), SUM(searches)), 4) AS zrr,
    ROUND(AVG(avg_click_rank), 2) AS avg_click_rank

  FROM query_metrics
  GROUP BY 1, 2, 3
),

-- ===== COMPARISON: CONTROL VS TREATMENT BY TIER =====
tier_comparison AS (
  SELECT
    COALESCE(control.search_vertical, treatment.search_vertical, 'NULL_VERTICAL') AS search_vertical,
    COALESCE(control.frequency_tier, treatment.frequency_tier) AS frequency_tier,

    -- Tier definition
    CASE COALESCE(control.frequency_tier, treatment.frequency_tier)
      WHEN 'Head' THEN 'Top 50% of combined volume'
      WHEN 'Torso' THEN 'Next 30% of combined volume (50-80%)'
      WHEN 'Tail' THEN 'Bottom 20% of combined volume (80-100%)'
    END AS tier_definition,

    -- Control metrics
    control.unique_queries AS control_unique_queries,
    control.total_searches AS control_searches,
    control.ctr AS control_ctr,
    control.cvr AS control_cvr,
    control.zrr AS control_zrr,
    control.avg_click_rank AS control_avg_click_rank,

    -- Treatment metrics
    treatment.unique_queries AS treatment_unique_queries,
    treatment.total_searches AS treatment_searches,
    treatment.ctr AS treatment_ctr,
    treatment.cvr AS treatment_cvr,
    treatment.zrr AS treatment_zrr,
    treatment.avg_click_rank AS treatment_avg_click_rank,

    -- Percentage changes
    ROUND(SAFE_DIVIDE(treatment.ctr - control.ctr, NULLIF(control.ctr, 0)) * 100, 2) AS ctr_pct_change,
    ROUND(SAFE_DIVIDE(treatment.cvr - control.cvr, NULLIF(control.cvr, 0)) * 100, 2) AS cvr_pct_change,
    ROUND(SAFE_DIVIDE(treatment.zrr - control.zrr, NULLIF(control.zrr, 0)) * 100, 2) AS zrr_pct_change,

    -- Statistical significance
    CASE
      WHEN COALESCE(control.total_searches, 0) < 30 OR COALESCE(treatment.total_searches, 0) < 30 THEN 'Insufficient Data'
      WHEN control.cvr IS NULL OR treatment.cvr IS NULL THEN 'N/A'
      WHEN control.cvr = 0 AND treatment.cvr = 0 THEN 'No Orders'
      WHEN ABS(
        (treatment.cvr - control.cvr) /
        NULLIF(SQRT(
          ((control.total_orders + treatment.total_orders) / (control.total_searches + treatment.total_searches)) *
          (1 - (control.total_orders + treatment.total_orders) / (control.total_searches + treatment.total_searches)) *
          (1.0/control.total_searches + 1.0/treatment.total_searches)
        ), 0)
      ) > 1.96 THEN 'Yes'
      ELSE 'No'
    END AS cvr_stat_sig,

    CASE
      WHEN COALESCE(control.total_searches, 0) < 30 OR COALESCE(treatment.total_searches, 0) < 30 THEN 'Insufficient Data'
      WHEN control.ctr IS NULL OR treatment.ctr IS NULL THEN 'N/A'
      WHEN control.ctr = 0 AND treatment.ctr = 0 THEN 'No Clicks'
      WHEN ABS(
        (treatment.ctr - control.ctr) /
        NULLIF(SQRT(
          ((control.total_clicks + treatment.total_clicks) / (control.total_searches + treatment.total_searches)) *
          (1 - (control.total_clicks + treatment.total_clicks) / (control.total_searches + treatment.total_searches)) *
          (1.0/control.total_searches + 1.0/treatment.total_searches)
        ), 0)
      ) > 1.96 THEN 'Yes'
      ELSE 'No'
    END AS ctr_stat_sig

  FROM (SELECT * FROM tier_aggregates WHERE variation = 'A') control
  FULL OUTER JOIN (SELECT * FROM tier_aggregates WHERE variation = 'B') treatment
    ON COALESCE(control.search_vertical, 'NULL_VERTICAL') = COALESCE(treatment.search_vertical, 'NULL_VERTICAL')
    AND COALESCE(control.frequency_tier, '') = COALESCE(treatment.frequency_tier, '')
)

-- Final output
SELECT
  FORMAT_DATE('%Y-%m-%d', report_date) AS report_date,
  search_vertical,
  frequency_tier,
  tier_definition,

  -- Volume metrics
  control_searches,
  treatment_searches,
  control_unique_queries,
  treatment_unique_queries,

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

FROM tier_comparison
ORDER BY
  search_vertical,
  CASE frequency_tier
    WHEN 'Head' THEN 1
    WHEN 'Torso' THEN 2
    WHEN 'Tail' THEN 3
  END;
