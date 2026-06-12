-- =================================================================
-- HEAD / TORSO / TAIL COMPARISON QUERY (UNIFIED VOLUME-BASED TIERS)
-- Tiers based on COMBINED traffic (Woowa + Global Search)
-- Top 50% volume = Head, Next 30% = Torso, Bottom 20% = Tail
-- =================================================================
DECLARE start_date DATE DEFAULT '2026-05-30';  -- AB test start date
DECLARE end_date DATE DEFAULT CURRENT_DATE() - 1;  -- Yesterday (D+1 lag)
-- For multiple days: CURRENT_DATE() - 7 to CURRENT_DATE()
-- =================================================================

WITH events AS (
  SELECT
    DATE(eventTimestamp) AS partition_date,
    eventTimestamp,
    globalEntityId       AS global_entity_id,
    sessionId            AS session_key,
    JSON_VALUE(eventVariablesJson, '$.searchTrackingId') AS search_request_id,
    eventAction AS event_name,
    eventOrigin AS event_origin,
    screenType,
    screenName,
    SAFE_CAST(JSON_VALUE(eventVariablesJson, '$.shopQuantityTotal') AS INT64) AS shop_quantity_total,
    JSON_VALUE(eventVariablesJson, '$.searchVerticalName') AS search_vertical,
    JSON_VALUE(eventVariablesJson, '$.searchTerm') AS search_term,
    JSON_VALUE(eventVariablesJson, '$.shopListType') AS shop_list_type,
    JSON_VALUE(eventVariablesJson, '$.shopListTrigger') AS shop_list_trigger,
    JSON_VALUE(eventVariablesJson, '$.eventOrigin') AS event_origin_json,
    JSON_VALUE(eventVariablesJson, '$.shopsIds') AS shops_ids,
    JSON_VALUE(eventVariablesJson, '$.shopId') AS shop_id
  FROM `fulfillment-dwh-production.curated_data_shared_data_stream_perseus.baemin_korea_perseus`
  WHERE DATE(eventTimestamp) BETWEEN start_date AND end_date
    AND eventAction IN ('shop_list.updated','shop.clicked','shop_list.expanded','transaction')
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
    FROM events
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
    e.global_entity_id,
    e.session_key,
    e.search_request_id,
    sp.correct_position
  FROM events e
  INNER JOIN shop_positions sp
    ON e.search_request_id = sp.search_request_id
    AND e.shop_id = sp.shop_id
  WHERE e.event_name = 'shop.clicked'
),

search_grain AS (
  SELECT
    partition_date,
    CASE
      WHEN s.google_project_id LIKE 'aws-search-woowa-cell-%' THEN 'aws-search-woowa-cells-combined'
      ELSE s.google_project_id
    END AS account_id_group,
    events.global_entity_id,
    search_request_id,
    ANY_VALUE(session_key) AS session_key,
    ANY_VALUE(search_term) AS search_term,
    MAX(IF(event_name='shop_list.updated', search_vertical, NULL)) AS search_vertical,
    MAX(IF(event_name='shop_list.updated', event_origin, NULL)) AS event_origin,
    MAX(IF(event_name='shop_list.updated', shop_list_type, NULL)) AS shop_list_type,
    MAX(IF(event_name='shop_list.updated', shop_list_trigger, NULL)) AS shop_list_trigger,
    MAX(IF(event_name='shop_list.updated', shop_quantity_total, NULL)) AS shop_quantity_total,
    COUNTIF(event_name='shop.clicked') > 0 AS had_click,
    COUNTIF(event_name='transaction') > 0 AS had_order,
    COUNTIF(event_name='shop_list.expanded') > 0 AS had_pagination,
    (SELECT AVG(correct_position) FROM clicks_with_positions cwp WHERE cwp.search_request_id = events.search_request_id) AS avg_click_rank,
    (SELECT MIN(correct_position) FROM clicks_with_positions cwp WHERE cwp.search_request_id = events.search_request_id) AS first_click_rank,
    COUNTIF(event_name='shop.clicked') AS click_count
  FROM events
  INNER JOIN `search-restaurant-stats-9826.backendtracking.vendor-v1` s
    ON s.global_entity_id = events.global_entity_id
    AND events.session_key = s.perseus_session_id
    AND events.search_request_id = s.request_id
    AND DATE(timestamp_utc) BETWEEN start_date AND end_date
  WHERE search_request_id IS NOT NULL
  GROUP BY 1, 2, 3, 4

  UNION ALL

  SELECT
    partition_date,
    'non-global-food-search' AS account_id_group,
    events.global_entity_id,
    search_request_id,
    ANY_VALUE(session_key) AS session_key,
    ANY_VALUE(search_term) AS search_term,
    MAX(IF(event_name='shop_list.updated', search_vertical, NULL)) AS search_vertical,
    MAX(IF(event_name='shop_list.updated', event_origin, NULL)) AS event_origin,
    MAX(IF(event_name='shop_list.updated', shop_list_type, NULL)) AS shop_list_type,
    MAX(IF(event_name='shop_list.updated', shop_list_trigger, NULL)) AS shop_list_trigger,
    MAX(IF(event_name='shop_list.updated', shop_quantity_total, NULL)) AS shop_quantity_total,
    COUNTIF(event_name='shop.clicked') > 0 AS had_click,
    COUNTIF(event_name='transaction') > 0 AS had_order,
    COUNTIF(event_name='shop_list.expanded') > 0 AS had_pagination,
    (SELECT AVG(correct_position) FROM clicks_with_positions cwp WHERE cwp.search_request_id = events.search_request_id) AS avg_click_rank,
    (SELECT MIN(correct_position) FROM clicks_with_positions cwp WHERE cwp.search_request_id = events.search_request_id) AS first_click_rank,
    COUNTIF(event_name='shop.clicked') AS click_count
  FROM events
  WHERE NOT EXISTS (
    SELECT 1
    FROM `search-restaurant-stats-9826.backendtracking.vendor-v1` AS s
    WHERE s.global_entity_id = events.global_entity_id
      AND events.session_key = s.perseus_session_id
      AND events.search_request_id = s.request_id
      AND DATE(timestamp_utc) BETWEEN start_date AND end_date
  )
  AND search_request_id IS NOT NULL
  GROUP BY 1, 2, 3, 4
),

-- ===== UNIFIED TIER CALCULATION (COMBINED VOLUME) =====
-- Calculate TOTAL volume across BOTH systems for tier assignment
combined_search_volume AS (
  SELECT
    search_vertical,
    search_term,
    COUNT(*) AS total_searches_combined,  -- Total across both systems
    SUM(COUNT(*)) OVER (
      PARTITION BY search_vertical
      ORDER BY COUNT(*) DESC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_searches,
    SUM(COUNT(*)) OVER (PARTITION BY search_vertical) AS total_searches_in_vertical
  FROM search_grain
  WHERE search_term IS NOT NULL
    AND search_vertical IN ('ALL', 'BAEMIN_DELIVERY')
  GROUP BY search_vertical, search_term
),

-- Assign tiers based on COMBINED volume percentages
unified_tier_assignment AS (
  SELECT
    search_vertical,
    search_term,
    total_searches_combined,
    cumulative_searches,
    total_searches_in_vertical,
    ROUND(cumulative_searches / total_searches_in_vertical * 100, 2) AS cumulative_pct,
    CASE
      WHEN cumulative_searches / total_searches_in_vertical <= 0.50 THEN 'Head'   -- Top 50% of combined volume
      WHEN cumulative_searches / total_searches_in_vertical <= 0.80 THEN 'Torso'  -- Next 30% of combined volume
      ELSE 'Tail'                                                                  -- Bottom 20% of combined volume
    END AS frequency_tier
  FROM combined_search_volume
),

-- Join unified tier back to search grain (applies same tier to both systems)
search_grain_with_tier AS (
  SELECT
    sg.*,
    uta.frequency_tier
  FROM search_grain sg
  LEFT JOIN unified_tier_assignment uta
    ON COALESCE(sg.search_vertical, 'NULL_VERTICAL') = COALESCE(uta.search_vertical, 'NULL_VERTICAL')
    AND sg.search_term = uta.search_term
),

-- Session-level metrics
session_metrics AS (
  SELECT
    account_id_group,
    frequency_tier,
    session_key,
    COUNT(DISTINCT search_request_id) AS searches_per_session,
    COUNTIF(had_click) AS clicks_in_session,
    COUNTIF(had_order) AS orders_in_session
  FROM search_grain_with_tier
  GROUP BY 1, 2, 3
),

-- Aggregate by frequency tier
aggregated_metrics AS (
  SELECT
    sg.account_id_group,
    sg.search_vertical,
    sg.frequency_tier,

    -- Volume metrics
    COUNT(*) AS searches,
    COUNT(DISTINCT sg.session_key) AS unique_sessions,
    COUNT(DISTINCT sg.search_term) AS unique_search_terms,

    -- Funnel metrics
    COUNTIF(had_click) AS clicks,
    COUNTIF(had_order) AS orders,
    COUNTIF(had_pagination) AS paginations,
    COUNTIF(shop_quantity_total = 0) AS zero_results,

    -- Filter usage
    COUNTIF(shop_list_trigger = 'filter_applied') AS searches_with_filters,

    -- Result quality metrics
    ROUND(AVG(shop_quantity_total), 1) AS avg_results,

    -- Click rank metrics
    ROUND(AVG(avg_click_rank), 2) AS avg_click_rank,
    ROUND(AVG(first_click_rank), 2) AS avg_first_click_rank,
    COUNTIF(first_click_rank = 1) AS clicks_on_position_1,
    COUNTIF(first_click_rank BETWEEN 2 AND 3) AS clicks_on_position_2_3,
    COUNTIF(first_click_rank BETWEEN 4 AND 10) AS clicks_on_position_4_10,
    COUNTIF(first_click_rank > 10) AS clicks_on_position_11_plus,

    -- Rates
    ROUND(SAFE_DIVIDE(COUNTIF(had_click), COUNT(*)), 4) AS ctr,
    ROUND(SAFE_DIVIDE(COUNTIF(had_order), COUNT(*)), 4) AS cvr,
    ROUND(SAFE_DIVIDE(COUNTIF(shop_quantity_total = 0), COUNT(*)), 4) AS zrr,
    ROUND(SAFE_DIVIDE(COUNTIF(had_pagination), COUNT(*)), 4) AS pagination_rate,

    -- Session-level metrics
    ROUND(AVG(sm.searches_per_session), 2) AS avg_searches_per_session,
    COUNTIF(sm.searches_per_session > 1) AS sessions_with_multiple_searches

  FROM search_grain_with_tier sg
  LEFT JOIN session_metrics sm
    ON sg.account_id_group = sm.account_id_group
    AND sg.frequency_tier = sm.frequency_tier
    AND sg.session_key = sm.session_key
  WHERE sg.search_term IS NOT NULL
    AND sg.search_vertical IN ('ALL', 'BAEMIN_DELIVERY')  -- Exclude NULL vertical (not actual search traffic - browsing/favorites)
  GROUP BY 1, 2, 3
)

-- Final comparison output by frequency tier
SELECT
  COALESCE(woowa_search.search_vertical, global_search.search_vertical, 'NULL_VERTICAL') AS search_vertical,
  COALESCE(woowa_search.frequency_tier, global_search.frequency_tier) AS frequency_tier,

  -- Tier Definition
  CASE COALESCE(woowa_search.frequency_tier, global_search.frequency_tier)
    WHEN 'Head' THEN 'Top 50% of combined volume'
    WHEN 'Torso' THEN 'Next 30% of combined volume (50-80%)'
    WHEN 'Tail' THEN 'Bottom 20% of combined volume (80-100%)'
  END AS tier_definition,

  -- ============= WOOWA SEARCH METRICS =============
  woowa_search.searches AS woowa_search_searches,
  woowa_search.unique_sessions AS woowa_search_unique_sessions,
  woowa_search.unique_search_terms AS woowa_search_unique_search_terms,
  ROUND(SAFE_DIVIDE(woowa_search.searches, woowa_search.unique_search_terms), 1) AS woowa_search_avg_searches_per_term,
  ROUND(SAFE_DIVIDE(woowa_search.searches, NULLIF((
    SELECT SUM(searches) FROM aggregated_metrics WHERE account_id_group = 'non-global-food-search' AND search_vertical = woowa_search.search_vertical
  ), 0)) * 100, 1) AS woowa_search_pct_of_vertical_volume,
  woowa_search.avg_results AS woowa_search_avg_results,
  woowa_search.zero_results AS woowa_search_zero_results,
  woowa_search.zrr AS woowa_search_zrr,
  woowa_search.ctr AS woowa_search_ctr,
  woowa_search.cvr AS woowa_search_cvr,
  woowa_search.avg_click_rank AS woowa_search_avg_click_rank,
  woowa_search.pagination_rate AS woowa_search_pagination_rate,
  woowa_search.avg_searches_per_session AS woowa_search_avg_searches_per_session,

  -- Click distribution percentages
  ROUND(SAFE_DIVIDE(woowa_search.clicks_on_position_1, woowa_search.clicks) * 100, 1) AS woowa_search_pct_clicks_pos_1,
  ROUND(SAFE_DIVIDE(woowa_search.clicks_on_position_2_3, woowa_search.clicks) * 100, 1) AS woowa_search_pct_clicks_pos_2_3,

  -- Filter usage percentage
  ROUND(SAFE_DIVIDE(woowa_search.searches_with_filters, woowa_search.searches) * 100, 1) AS woowa_search_pct_searches_with_filters,

  -- ============= GLOBAL SEARCH METRICS =============
  global_search.searches AS global_search_searches,
  global_search.unique_sessions AS global_search_unique_sessions,
  global_search.unique_search_terms AS global_search_unique_search_terms,
  ROUND(SAFE_DIVIDE(global_search.searches, global_search.unique_search_terms), 1) AS global_search_avg_searches_per_term,
  ROUND(SAFE_DIVIDE(global_search.searches, NULLIF((
    SELECT SUM(searches) FROM aggregated_metrics WHERE account_id_group = 'aws-search-woowa-cells-combined' AND search_vertical = global_search.search_vertical
  ), 0)) * 100, 1) AS global_search_pct_of_vertical_volume,
  global_search.avg_results AS global_search_avg_results,
  global_search.zero_results AS global_search_zero_results,
  global_search.zrr AS global_search_zrr,
  global_search.ctr AS global_search_ctr,
  global_search.cvr AS global_search_cvr,
  global_search.avg_click_rank AS global_search_avg_click_rank,
  global_search.pagination_rate AS global_search_pagination_rate,
  global_search.avg_searches_per_session AS global_search_avg_searches_per_session,

  -- Click distribution percentages
  ROUND(SAFE_DIVIDE(global_search.clicks_on_position_1, global_search.clicks) * 100, 1) AS global_search_pct_clicks_pos_1,
  ROUND(SAFE_DIVIDE(global_search.clicks_on_position_2_3, global_search.clicks) * 100, 1) AS global_search_pct_clicks_pos_2_3,

  -- Filter usage percentage
  ROUND(SAFE_DIVIDE(global_search.searches_with_filters, global_search.searches) * 100, 1) AS global_search_pct_searches_with_filters,

  -- ============= COMPARISON METRICS =============
  -- Volume comparison
  global_search.searches - woowa_search.searches AS search_volume_diff,
  ROUND(SAFE_DIVIDE(global_search.searches - woowa_search.searches, NULLIF(woowa_search.searches, 0)) * 100, 2) AS search_volume_pct_change,

  -- CTR comparison
  ROUND((global_search.ctr - woowa_search.ctr) * 100, 2) AS ctr_absolute_change,
  ROUND(SAFE_DIVIDE(global_search.ctr - woowa_search.ctr, NULLIF(woowa_search.ctr, 0)) * 100, 2) AS ctr_pct_change,

  -- CVR comparison
  ROUND((global_search.cvr - woowa_search.cvr) * 100, 2) AS cvr_absolute_change,
  ROUND(SAFE_DIVIDE(global_search.cvr - woowa_search.cvr, NULLIF(woowa_search.cvr, 0)) * 100, 2) AS cvr_pct_change,

  -- ZRR comparison
  ROUND((global_search.zrr - woowa_search.zrr) * 100, 2) AS zrr_absolute_change,
  ROUND(SAFE_DIVIDE(global_search.zrr - woowa_search.zrr, NULLIF(woowa_search.zrr, 0)) * 100, 2) AS zrr_pct_change,

  -- Click rank comparison
  ROUND(global_search.avg_click_rank - woowa_search.avg_click_rank, 2) AS avg_click_rank_diff,

  -- Statistical significance for CTR
  CASE
    WHEN woowa_search.searches < 30 OR global_search.searches < 30 THEN 'Insufficient Data'
    WHEN woowa_search.ctr IS NULL OR global_search.ctr IS NULL THEN 'N/A'
    WHEN ABS(
      (global_search.ctr - woowa_search.ctr) / NULLIF(
        SQRT(
          (woowa_search.ctr * (1 - woowa_search.ctr) / NULLIF(woowa_search.searches, 0)) +
          (global_search.ctr * (1 - global_search.ctr) / NULLIF(global_search.searches, 0))
        ), 0
      )
    ) > 1.96 THEN 'Yes'
    ELSE 'No'
  END AS ctr_statistically_significant,

  -- Statistical significance for CVR
  CASE
    WHEN woowa_search.searches < 30 OR global_search.searches < 30 THEN 'Insufficient Data'
    WHEN woowa_search.cvr IS NULL OR global_search.cvr IS NULL THEN 'N/A'
    WHEN ABS(
      (global_search.cvr - woowa_search.cvr) / NULLIF(
        SQRT(
          (woowa_search.cvr * (1 - woowa_search.cvr) / NULLIF(woowa_search.searches, 0)) +
          (global_search.cvr * (1 - global_search.cvr) / NULLIF(global_search.searches, 0))
        ), 0
      )
    ) > 1.96 THEN 'Yes'
    ELSE 'No'
  END AS cvr_statistically_significant

FROM
  (SELECT * FROM aggregated_metrics WHERE account_id_group = 'non-global-food-search') woowa_search
FULL OUTER JOIN
  (SELECT * FROM aggregated_metrics WHERE account_id_group = 'aws-search-woowa-cells-combined') global_search
  ON COALESCE(woowa_search.search_vertical, 'NULL_VERTICAL') = COALESCE(global_search.search_vertical, 'NULL_VERTICAL')
  AND woowa_search.frequency_tier = global_search.frequency_tier

ORDER BY
  CASE search_vertical
    WHEN 'ALL' THEN 1
    WHEN 'BAEMIN_DELIVERY' THEN 2
    WHEN 'NULL_VERTICAL' THEN 3
    ELSE 4
  END,
  CASE frequency_tier
    WHEN 'Head' THEN 1
    WHEN 'Torso' THEN 2
    WHEN 'Tail' THEN 3
  END;
