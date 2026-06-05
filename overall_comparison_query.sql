-- =================================================================
-- OVERALL COMPARISON QUERY - ALL SEARCHES AGGREGATED
-- High-level performance comparison across all search queries
-- =================================================================
DECLARE start_date DATE DEFAULT CURRENT_DATE();  -- Today
DECLARE end_date DATE DEFAULT CURRENT_DATE();    -- Today
-- For multiple days: CURRENT_DATE() - 7 to CURRENT_DATE() - 1
-- =================================================================

WITH events AS (
  SELECT
    DATE(eventTimestamp) AS partition_date,
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

-- Get correct shop positions from shop_list.updated baseline
shop_positions AS (
  SELECT
    search_request_id,
    shop_id,
    position as correct_position
  FROM events,
  UNNEST(SPLIT(shops_ids, ',')) as shop_id WITH OFFSET as position
  WHERE event_name = 'shop_list.updated'
    AND shops_ids IS NOT NULL
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
    events.partition_date,
    CASE
      WHEN s.google_project_id LIKE 'aws-search-woowa-cell-%' THEN 'aws-search-woowa-cells-combined'
      ELSE s.google_project_id
    END AS account_id_group,
    events.global_entity_id,
    events.search_request_id,
    ANY_VALUE(events.session_key) AS session_key,
    ANY_VALUE(events.search_term) AS search_term,
    MAX(IF(events.event_name='shop_list.updated', events.search_vertical, NULL)) AS search_vertical,
    MAX(IF(events.event_name='shop_list.updated', events.event_origin, NULL)) AS event_origin,
    MAX(IF(events.event_name='shop_list.updated', events.shop_list_type, NULL)) AS shop_list_type,
    MAX(IF(events.event_name='shop_list.updated', events.shop_list_trigger, NULL)) AS shop_list_trigger,
    MAX(IF(events.event_name='shop_list.updated', events.shop_quantity_total, NULL)) AS shop_quantity_total,
    COUNTIF(events.event_name='shop.clicked') > 0 AS had_click,
    COUNTIF(events.event_name='transaction') > 0 AS had_order,
    COUNTIF(events.event_name='shop_list.expanded') > 0 AS had_pagination,
    -- Click rank metrics using CORRECTED positions from shop_list.updated
    (SELECT AVG(correct_position) FROM clicks_with_positions cwp WHERE cwp.search_request_id = events.search_request_id) AS avg_click_rank,
    (SELECT MIN(correct_position) FROM clicks_with_positions cwp WHERE cwp.search_request_id = events.search_request_id) AS first_click_rank,
    COUNTIF(events.event_name='shop.clicked') AS click_count
  FROM events
  INNER JOIN `search-restaurant-stats-9826.backendtracking.vendor-v1` s
    ON s.global_entity_id = events.global_entity_id
    AND events.session_key = s.perseus_session_id
    AND events.search_request_id = s.request_id
    AND DATE(timestamp_utc) BETWEEN start_date AND end_date
  WHERE events.search_request_id IS NOT NULL
  GROUP BY 1, 2, 3, 4

  UNION ALL

  SELECT
    events.partition_date,
    'non-global-food-search' AS account_id_group,
    events.global_entity_id,
    events.search_request_id,
    ANY_VALUE(events.session_key) AS session_key,
    ANY_VALUE(events.search_term) AS search_term,
    MAX(IF(events.event_name='shop_list.updated', events.search_vertical, NULL)) AS search_vertical,
    MAX(IF(events.event_name='shop_list.updated', events.event_origin, NULL)) AS event_origin,
    MAX(IF(events.event_name='shop_list.updated', events.shop_list_type, NULL)) AS shop_list_type,
    MAX(IF(events.event_name='shop_list.updated', events.shop_list_trigger, NULL)) AS shop_list_trigger,
    MAX(IF(events.event_name='shop_list.updated', events.shop_quantity_total, NULL)) AS shop_quantity_total,
    COUNTIF(events.event_name='shop.clicked') > 0 AS had_click,
    COUNTIF(events.event_name='transaction') > 0 AS had_order,
    COUNTIF(events.event_name='shop_list.expanded') > 0 AS had_pagination,
    -- Click rank metrics using CORRECTED positions from shop_list.updated
    (SELECT AVG(correct_position) FROM clicks_with_positions cwp WHERE cwp.search_request_id = events.search_request_id) AS avg_click_rank,
    (SELECT MIN(correct_position) FROM clicks_with_positions cwp WHERE cwp.search_request_id = events.search_request_id) AS first_click_rank,
    COUNTIF(events.event_name='shop.clicked') AS click_count
  FROM events
  WHERE NOT EXISTS (
    SELECT 1
    FROM `search-restaurant-stats-9826.backendtracking.vendor-v1` AS s
    WHERE s.global_entity_id = events.global_entity_id
      AND events.session_key = s.perseus_session_id
      AND events.search_request_id = s.request_id
      AND DATE(timestamp_utc) BETWEEN start_date AND end_date
  )
  AND events.search_request_id IS NOT NULL
  GROUP BY 1, 2, 3, 4
),

-- Session-level metrics
session_metrics AS (
  SELECT
    account_id_group,
    session_key,
    COUNT(DISTINCT search_request_id) AS searches_per_session,
    COUNTIF(had_click) AS clicks_in_session,
    COUNTIF(had_order) AS orders_in_session
  FROM search_grain
  GROUP BY 1, 2
),

-- Overall aggregated metrics by vertical
aggregated_metrics AS (
  SELECT
    sg.account_id_group,
    sg.search_vertical,

    -- Volume metrics
    COUNT(*) AS searches,
    COUNT(DISTINCT sg.session_key) AS unique_sessions,
    COUNT(DISTINCT sg.search_term) AS unique_search_terms,

    -- Funnel metrics
    COUNTIF(had_click) AS clicks,
    COUNTIF(had_order) AS orders,
    COUNTIF(had_pagination) AS paginations,
    COUNTIF(shop_quantity_total = 0) AS zero_results,

    -- Filter usage metrics
    COUNTIF(shop_list_trigger = 'filter_applied') AS searches_with_filters,
    COUNTIF(shop_list_trigger = 'vertical_change') AS searches_with_vertical_change,

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

    -- Session-level metrics (avg)
    ROUND(AVG(sm.searches_per_session), 2) AS avg_searches_per_session,
    COUNTIF(sm.searches_per_session > 1) AS sessions_with_multiple_searches,

    -- Filter impact (CTR with vs without filters)
    ROUND(SAFE_DIVIDE(
      COUNTIF(had_click AND shop_list_trigger = 'filter_applied'),
      NULLIF(COUNTIF(shop_list_trigger = 'filter_applied'), 0)
    ), 4) AS ctr_with_filters,
    ROUND(SAFE_DIVIDE(
      COUNTIF(had_click AND shop_list_trigger = 'search'),
      NULLIF(COUNTIF(shop_list_trigger = 'search'), 0)
    ), 4) AS ctr_without_filters,

    -- Pagination impact (CTR with vs without pagination)
    ROUND(SAFE_DIVIDE(
      COUNTIF(had_click AND had_pagination),
      NULLIF(COUNTIF(had_pagination), 0)
    ), 4) AS ctr_with_pagination,
    ROUND(SAFE_DIVIDE(
      COUNTIF(had_click AND NOT had_pagination),
      NULLIF(COUNTIF(NOT had_pagination), 0)
    ), 4) AS ctr_without_pagination

  FROM search_grain sg
  LEFT JOIN session_metrics sm
    ON sg.account_id_group = sm.account_id_group
    AND sg.session_key = sm.session_key
  WHERE
    -- Include only ALL and BAEMIN_DELIVERY verticals
    -- Exclude BAEMIN_TAKEOUT (not served by Global Search)
    -- Exclude NULL vertical (not actual search traffic - browsing/favorites)
    sg.search_vertical IN ('ALL', 'BAEMIN_DELIVERY')
  GROUP BY 1, 2
)

-- Final overall comparison output
SELECT
  COALESCE(woowa_search.search_vertical, global_search.search_vertical, 'NULL_VERTICAL') AS search_vertical,

  -- ============= NON-GLOBAL OVERALL METRICS =============
  woowa_search.searches AS woowa_search_total_searches,
  woowa_search.unique_sessions AS woowa_search_unique_sessions,
  woowa_search.unique_search_terms AS woowa_search_unique_search_terms,
  woowa_search.avg_results AS woowa_search_avg_results,
  woowa_search.zero_results AS woowa_search_zero_results,
  woowa_search.zrr AS woowa_search_zrr,
  woowa_search.ctr AS woowa_search_ctr,
  woowa_search.cvr AS woowa_search_cvr,

  -- Pagination
  woowa_search.pagination_rate AS woowa_search_pagination_rate,
  woowa_search.ctr_with_pagination AS woowa_search_ctr_with_pagination,
  woowa_search.ctr_without_pagination AS woowa_search_ctr_without_pagination,

  -- Click rank
  woowa_search.avg_click_rank AS woowa_search_avg_click_rank,
  woowa_search.clicks_on_position_1 AS woowa_search_clicks_pos_1,
  woowa_search.clicks_on_position_2_3 AS woowa_search_clicks_pos_2_3,
  woowa_search.clicks_on_position_4_10 AS woowa_search_clicks_pos_4_10,
  woowa_search.clicks_on_position_11_plus AS woowa_search_clicks_pos_11_plus,
  ROUND(SAFE_DIVIDE(woowa_search.clicks_on_position_1, woowa_search.clicks) * 100, 1) AS woowa_search_pct_clicks_pos_1,
  ROUND(SAFE_DIVIDE(woowa_search.clicks_on_position_2_3, woowa_search.clicks) * 100, 1) AS woowa_search_pct_clicks_pos_2_3,

  -- Filters
  woowa_search.searches_with_filters AS woowa_search_searches_with_filters,
  ROUND(SAFE_DIVIDE(woowa_search.searches_with_filters, woowa_search.searches) * 100, 1) AS woowa_search_pct_searches_with_filters,
  woowa_search.ctr_with_filters AS woowa_search_ctr_with_filters,
  woowa_search.ctr_without_filters AS woowa_search_ctr_without_filters,

  -- Sessions
  woowa_search.avg_searches_per_session AS woowa_search_avg_searches_per_session,
  woowa_search.sessions_with_multiple_searches AS woowa_search_multi_search_sessions,
  ROUND(SAFE_DIVIDE(woowa_search.sessions_with_multiple_searches, woowa_search.unique_sessions) * 100, 1) AS woowa_search_pct_multi_search_sessions,

  -- ============= AWS CELLS OVERALL METRICS =============
  global_search.searches AS global_search_total_searches,
  global_search.unique_sessions AS global_search_unique_sessions,
  global_search.unique_search_terms AS global_search_unique_search_terms,
  global_search.avg_results AS global_search_avg_results,
  global_search.zero_results AS global_search_zero_results,
  global_search.zrr AS global_search_zrr,
  global_search.ctr AS global_search_ctr,
  global_search.cvr AS global_search_cvr,

  -- Pagination
  global_search.pagination_rate AS global_search_pagination_rate,
  global_search.ctr_with_pagination AS global_search_ctr_with_pagination,
  global_search.ctr_without_pagination AS global_search_ctr_without_pagination,

  -- Click rank
  global_search.avg_click_rank AS global_search_avg_click_rank,
  global_search.clicks_on_position_1 AS global_search_clicks_pos_1,
  global_search.clicks_on_position_2_3 AS global_search_clicks_pos_2_3,
  global_search.clicks_on_position_4_10 AS global_search_clicks_pos_4_10,
  global_search.clicks_on_position_11_plus AS global_search_clicks_pos_11_plus,
  ROUND(SAFE_DIVIDE(global_search.clicks_on_position_1, global_search.clicks) * 100, 1) AS global_search_pct_clicks_pos_1,
  ROUND(SAFE_DIVIDE(global_search.clicks_on_position_2_3, global_search.clicks) * 100, 1) AS global_search_pct_clicks_pos_2_3,

  -- Filters
  global_search.searches_with_filters AS global_search_searches_with_filters,
  ROUND(SAFE_DIVIDE(global_search.searches_with_filters, global_search.searches) * 100, 1) AS global_search_pct_searches_with_filters,
  global_search.ctr_with_filters AS global_search_ctr_with_filters,
  global_search.ctr_without_filters AS global_search_ctr_without_filters,

  -- Sessions
  global_search.avg_searches_per_session AS global_search_avg_searches_per_session,
  global_search.sessions_with_multiple_searches AS global_search_multi_search_sessions,
  ROUND(SAFE_DIVIDE(global_search.sessions_with_multiple_searches, global_search.unique_sessions) * 100, 1) AS global_search_pct_multi_search_sessions,

  -- ============= COMPARISON METRICS =============
  -- Absolute differences
  global_search.searches - woowa_search.searches AS search_volume_diff,
  ROUND(global_search.ctr - woowa_search.ctr, 4) AS ctr_absolute_diff,
  ROUND(global_search.cvr - woowa_search.cvr, 4) AS cvr_absolute_diff,
  ROUND(global_search.zrr - woowa_search.zrr, 4) AS zrr_absolute_diff,

  -- Percentage changes
  ROUND(SAFE_DIVIDE(global_search.searches - woowa_search.searches, NULLIF(woowa_search.searches, 0)) * 100, 1) AS search_volume_pct_change,
  ROUND(SAFE_DIVIDE(global_search.ctr - woowa_search.ctr, NULLIF(woowa_search.ctr, 0)) * 100, 2) AS ctr_pct_change,
  ROUND(SAFE_DIVIDE(global_search.cvr - woowa_search.cvr, NULLIF(woowa_search.cvr, 0)) * 100, 2) AS cvr_pct_change,
  ROUND(SAFE_DIVIDE(global_search.zrr - woowa_search.zrr, NULLIF(woowa_search.zrr, 0)) * 100, 2) AS zrr_pct_change,
  ROUND(SAFE_DIVIDE(global_search.pagination_rate - woowa_search.pagination_rate, NULLIF(woowa_search.pagination_rate, 0)) * 100, 2) AS pagination_rate_pct_change,
  ROUND(global_search.avg_click_rank - woowa_search.avg_click_rank, 2) AS avg_click_rank_diff,
  ROUND(SAFE_DIVIDE(global_search.avg_searches_per_session - woowa_search.avg_searches_per_session, NULLIF(woowa_search.avg_searches_per_session, 0)) * 100, 2) AS searches_per_session_pct_change,

  -- ============= STATISTICAL SIGNIFICANCE =============
  CASE
    WHEN woowa_search.searches IS NULL OR global_search.searches IS NULL THEN 'N/A'
    WHEN woowa_search.searches < 30 OR global_search.searches < 30 THEN 'Insufficient Data'
    WHEN woowa_search.ctr = 0 AND global_search.ctr = 0 THEN 'No Clicks'
    ELSE
      CASE
        WHEN ABS(
          (global_search.ctr - woowa_search.ctr) /
          NULLIF(SQRT(
            ((woowa_search.clicks + global_search.clicks) / (woowa_search.searches + global_search.searches)) *
            (1 - (woowa_search.clicks + global_search.clicks) / (woowa_search.searches + global_search.searches)) *
            (1.0/woowa_search.searches + 1.0/global_search.searches)
          ), 0)
        ) > 1.96 THEN 'Yes'
        ELSE 'No'
      END
  END AS ctr_statistically_significant,

  CASE
    WHEN woowa_search.searches IS NULL OR global_search.searches IS NULL THEN 'N/A'
    WHEN woowa_search.searches < 30 OR global_search.searches < 30 THEN 'Insufficient Data'
    WHEN woowa_search.cvr = 0 AND global_search.cvr = 0 THEN 'No Orders'
    ELSE
      CASE
        WHEN ABS(
          (global_search.cvr - woowa_search.cvr) /
          NULLIF(SQRT(
            ((woowa_search.orders + global_search.orders) / (woowa_search.searches + global_search.searches)) *
            (1 - (woowa_search.orders + global_search.orders) / (woowa_search.searches + global_search.searches)) *
            (1.0/woowa_search.searches + 1.0/global_search.searches)
          ), 0)
        ) > 1.96 THEN 'Yes'
        ELSE 'No'
      END
  END AS cvr_statistically_significant,

  CURRENT_TIMESTAMP() AS execution_time

FROM
  (SELECT * FROM aggregated_metrics WHERE account_id_group = 'non-global-food-search') woowa_search
FULL OUTER JOIN
  (SELECT * FROM aggregated_metrics WHERE account_id_group = 'aws-search-woowa-cells-combined') global_search
  ON COALESCE(woowa_search.search_vertical, 'NULL_VERTICAL') = COALESCE(global_search.search_vertical, 'NULL_VERTICAL')
ORDER BY
  search_vertical;
