-- =================================================================
-- DAILY ALERT REPORT - Woowa Search vs Global Search
-- Automated daily monitoring with key alerts
-- =================================================================
DECLARE report_date DATE DEFAULT CURRENT_DATE();  -- Today
DECLARE comparison_date DATE DEFAULT CURRENT_DATE() - 7;  -- Week before for trend comparison
-- =================================================================

WITH events AS (
  SELECT
    DATE(eventTimestamp) AS partition_date,
    globalEntityId       AS global_entity_id,
    sessionId            AS session_key,
    JSON_VALUE(eventVariablesJson, '$.searchTrackingId') AS search_request_id,
    eventAction AS event_name,
    eventOrigin AS event_origin,
    SAFE_CAST(JSON_VALUE(eventVariablesJson, '$.shopQuantityTotal') AS INT64) AS shop_quantity_total,
    SAFE_CAST(JSON_VALUE(eventVariablesJson, '$.shopPosition') AS INT64) AS shop_position,
    JSON_VALUE(eventVariablesJson, '$.searchVerticalName') AS search_vertical,
    JSON_VALUE(eventVariablesJson, '$.searchTerm') AS search_term,
    JSON_VALUE(eventVariablesJson, '$.shopListTrigger') AS shop_list_trigger
  FROM `fulfillment-dwh-production.curated_data_shared_data_stream_perseus.baemin_korea_perseus`
  WHERE DATE(eventTimestamp) = report_date
    AND eventAction IN ('shop_list.updated','shop.clicked','shop_list.expanded','transaction')
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
    MAX(IF(event_name='shop_list.updated', shop_quantity_total, NULL)) AS shop_quantity_total,
    COUNTIF(event_name='shop.clicked') > 0 AS had_click,
    COUNTIF(event_name='transaction') > 0 AS had_order,
    MIN(IF(event_name='shop.clicked', shop_position, NULL)) AS first_click_rank
  FROM events
  INNER JOIN `search-restaurant-stats-9826.backendtracking.vendor-v1` s
    ON s.global_entity_id = events.global_entity_id
    AND events.session_key = s.perseus_session_id
    AND events.search_request_id = s.request_id
    AND DATE(timestamp_utc) = report_date
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
    MAX(IF(event_name='shop_list.updated', shop_quantity_total, NULL)) AS shop_quantity_total,
    COUNTIF(event_name='shop.clicked') > 0 AS had_click,
    COUNTIF(event_name='transaction') > 0 AS had_order,
    MIN(IF(event_name='shop.clicked', shop_position, NULL)) AS first_click_rank
  FROM events
  WHERE NOT EXISTS (
    SELECT 1
    FROM `search-restaurant-stats-9826.backendtracking.vendor-v1` AS s
    WHERE s.global_entity_id = events.global_entity_id
      AND events.session_key = s.perseus_session_id
      AND events.search_request_id = s.request_id
      AND DATE(timestamp_utc) = report_date
  )
  AND search_request_id IS NOT NULL
  GROUP BY 1, 2, 3, 4
),

-- ===== SECTION 1: Overall Metrics =====
overall_metrics AS (
  SELECT
    account_id_group,
    search_vertical,
    COUNT(*) AS searches,
    COUNT(DISTINCT session_key) AS unique_sessions,
    COUNT(DISTINCT search_term) AS unique_search_terms,
    COUNTIF(had_click) AS clicks,
    COUNTIF(had_order) AS orders,
    COUNTIF(shop_quantity_total = 0) AS zero_results,
    ROUND(SAFE_DIVIDE(COUNTIF(had_click), COUNT(*)), 4) AS ctr,
    ROUND(SAFE_DIVIDE(COUNTIF(had_order), COUNT(*)), 4) AS cvr,
    ROUND(SAFE_DIVIDE(COUNTIF(shop_quantity_total = 0), COUNT(*)), 4) AS zrr,
    ROUND(AVG(first_click_rank), 2) AS avg_click_rank
  FROM search_grain
  WHERE search_vertical IN ('ALL', 'BAEMIN_DELIVERY')
  GROUP BY 1, 2
),

overall_comparison AS (
  SELECT
    COALESCE(ws.search_vertical, gs.search_vertical, 'NULL_VERTICAL') AS search_vertical,
    ws.searches AS woowa_searches,
    gs.searches AS global_searches,
    ws.unique_sessions AS woowa_sessions,
    gs.unique_sessions AS global_sessions,
    ws.ctr AS woowa_ctr,
    gs.ctr AS global_ctr,
    ws.cvr AS woowa_cvr,
    gs.cvr AS global_cvr,
    ws.zrr AS woowa_zrr,
    gs.zrr AS global_zrr,

    -- Percentage changes
    ROUND(SAFE_DIVIDE(gs.ctr - ws.ctr, NULLIF(ws.ctr, 0)) * 100, 2) AS ctr_pct_change,
    ROUND(SAFE_DIVIDE(gs.cvr - ws.cvr, NULLIF(ws.cvr, 0)) * 100, 2) AS cvr_pct_change,
    ROUND(SAFE_DIVIDE(gs.zrr - ws.zrr, NULLIF(ws.zrr, 0)) * 100, 2) AS zrr_pct_change,

    -- Statistical significance for CVR
    CASE
      WHEN ws.searches < 30 OR gs.searches < 30 THEN 'Insufficient Data'
      WHEN ws.cvr IS NULL OR gs.cvr IS NULL THEN 'N/A'
      WHEN ABS((gs.cvr - ws.cvr) / NULLIF(SQRT(
        (ws.cvr * (1 - ws.cvr) / NULLIF(ws.searches, 0)) +
        (gs.cvr * (1 - gs.cvr) / NULLIF(gs.searches, 0))
      ), 0)) > 1.96 THEN 'Yes'
      ELSE 'No'
    END AS cvr_stat_sig,

    -- Statistical significance for CTR
    CASE
      WHEN ws.searches < 30 OR gs.searches < 30 THEN 'Insufficient Data'
      WHEN ws.ctr IS NULL OR gs.ctr IS NULL THEN 'N/A'
      WHEN ABS((gs.ctr - ws.ctr) / NULLIF(SQRT(
        (ws.ctr * (1 - ws.ctr) / NULLIF(ws.searches, 0)) +
        (gs.ctr * (1 - gs.ctr) / NULLIF(gs.searches, 0))
      ), 0)) > 1.96 THEN 'Yes'
      ELSE 'No'
    END AS ctr_stat_sig

  FROM (SELECT * FROM overall_metrics WHERE account_id_group = 'non-global-food-search') ws
  FULL OUTER JOIN (SELECT * FROM overall_metrics WHERE account_id_group = 'aws-search-woowa-cells-combined') gs
    ON COALESCE(ws.search_vertical, 'NULL_VERTICAL') = COALESCE(gs.search_vertical, 'NULL_VERTICAL')
),

-- ===== SECTION 2: Query-Level Analysis =====
query_metrics AS (
  SELECT
    account_id_group,
    search_vertical,
    search_term,
    COUNT(*) AS searches,
    COUNTIF(had_click) AS clicks,
    COUNTIF(had_order) AS orders,
    COUNTIF(shop_quantity_total = 0) AS zero_results,
    ROUND(SAFE_DIVIDE(COUNTIF(had_click), COUNT(*)), 4) AS ctr,
    ROUND(SAFE_DIVIDE(COUNTIF(had_order), COUNT(*)), 4) AS cvr,
    ROUND(SAFE_DIVIDE(COUNTIF(shop_quantity_total = 0), COUNT(*)), 4) AS zrr
  FROM search_grain
  WHERE search_term IS NOT NULL
    AND search_vertical IN ('ALL', 'BAEMIN_DELIVERY')
  GROUP BY 1, 2, 3
),

query_comparison AS (
  SELECT
    COALESCE(ws.search_vertical, gs.search_vertical, 'NULL_VERTICAL') AS search_vertical,
    COALESCE(ws.search_term, gs.search_term) AS search_query,
    ws.searches AS woowa_searches,
    gs.searches AS global_searches,
    ws.ctr AS woowa_ctr,
    gs.ctr AS global_ctr,
    ws.cvr AS woowa_cvr,
    gs.cvr AS global_cvr,
    ws.zrr AS woowa_zrr,
    gs.zrr AS global_zrr,

    -- Change metrics
    ROUND(SAFE_DIVIDE(gs.ctr - ws.ctr, NULLIF(ws.ctr, 0)) * 100, 2) AS ctr_pct_change,
    ROUND(SAFE_DIVIDE(gs.cvr - ws.cvr, NULLIF(ws.cvr, 0)) * 100, 2) AS cvr_pct_change,

    -- Statistical significance
    CASE
      WHEN COALESCE(ws.searches, 0) < 30 OR COALESCE(gs.searches, 0) < 30 THEN 'Insufficient Data'
      WHEN ws.cvr IS NULL OR gs.cvr IS NULL THEN 'N/A'
      WHEN ABS((gs.cvr - ws.cvr) / NULLIF(SQRT(
        (ws.cvr * (1 - ws.cvr) / NULLIF(ws.searches, 0)) +
        (gs.cvr * (1 - gs.cvr) / NULLIF(gs.searches, 0))
      ), 0)) > 1.96 THEN 'Yes'
      ELSE 'No'
    END AS cvr_stat_sig

  FROM (SELECT * FROM query_metrics WHERE account_id_group = 'non-global-food-search') ws
  FULL OUTER JOIN (SELECT * FROM query_metrics WHERE account_id_group = 'aws-search-woowa-cells-combined') gs
    ON COALESCE(ws.search_vertical, 'NULL_VERTICAL') = COALESCE(gs.search_vertical, 'NULL_VERTICAL')
    AND ws.search_term = gs.search_term
  WHERE gs.searches >= 5  -- Only queries with meaningful Global Search volume
),

-- ===== SECTION 3: Session Analysis =====
session_analysis AS (
  SELECT
    account_id_group,
    COUNT(DISTINCT session_key) AS total_sessions,
    COUNT(DISTINCT search_request_id) AS total_searches,
    ROUND(SAFE_DIVIDE(COUNT(DISTINCT search_request_id), COUNT(DISTINCT session_key)), 2) AS searches_per_session
  FROM search_grain
  GROUP BY 1
),

-- ===== FORMATTED OUTPUT =====
formatted_report AS (
  -- Overall Summary
  SELECT
    'OVERALL_SUMMARY' AS section,
    search_vertical AS detail,
    CONCAT(
      'Global Search: ', CAST(global_searches AS STRING), ' searches (',
      FORMAT('%.1f%%', SAFE_DIVIDE(global_searches, woowa_searches + global_searches) * 100), ' of traffic), ',
      'CTR: ', FORMAT('%.2f%%', global_ctr * 100), ' (',
      IF(ctr_pct_change > 0, '+', ''), FORMAT('%.1f%%', ctr_pct_change),
      IF(ctr_stat_sig = 'Yes', ' ✓ sig)', ')'), ', ',
      'CVR: ', FORMAT('%.2f%%', global_cvr * 100), ' (',
      IF(cvr_pct_change > 0, '+', ''), FORMAT('%.1f%%', cvr_pct_change),
      IF(cvr_stat_sig = 'Yes', ' ✓ sig)', ')'), ', ',
      'ZRR: ', FORMAT('%.2f%%', global_zrr * 100)
    ) AS alert_message,
    CASE
      WHEN cvr_stat_sig = 'Yes' AND cvr_pct_change < -10 THEN 'CRITICAL'
      WHEN cvr_stat_sig = 'Yes' AND cvr_pct_change < -5 THEN 'WARNING'
      WHEN zrr_pct_change > 20 THEN 'WARNING'
      WHEN cvr_stat_sig = 'Yes' AND cvr_pct_change > 10 THEN 'POSITIVE'
      ELSE 'INFO'
    END AS alert_level,
    1 AS sort_order
  FROM overall_comparison

  UNION ALL

  -- Top Failing Queries on Global Search
  SELECT
    'FAILING_QUERIES' AS section,
    search_query AS detail,
    CONCAT(
      'Query: "', search_query, '" - ',
      CAST(global_searches AS STRING), ' searches, ',
      'CTR: ', FORMAT('%.1f%%', global_ctr * 100), ' ',
      'CVR: ', FORMAT('%.1f%%', global_cvr * 100), ' ',
      'ZRR: ', FORMAT('%.1f%%', global_zrr * 100),
      IF(cvr_pct_change IS NOT NULL,
        CONCAT(' (', IF(cvr_pct_change > 0, '+', ''), FORMAT('%.1f%%', cvr_pct_change), ' vs Woowa)'),
        '')
    ) AS alert_message,
    CASE
      WHEN global_zrr > 0.15 THEN 'CRITICAL'
      WHEN global_ctr < 0.05 OR global_zrr > 0.10 THEN 'WARNING'
      ELSE 'INFO'
    END AS alert_level,
    2 AS sort_order
  FROM query_comparison
  WHERE global_searches >= 20  -- Only meaningful volume
    AND (global_ctr < 0.08 OR global_zrr > 0.10 OR global_cvr < woowa_cvr * 0.8)
  ORDER BY global_searches DESC
  LIMIT 10

  UNION ALL

  -- Top Improving Queries
  SELECT
    'IMPROVING_QUERIES' AS section,
    search_query AS detail,
    CONCAT(
      'Query: "', search_query, '" - ',
      CAST(global_searches AS STRING), ' searches, ',
      'CVR: ', FORMAT('%.1f%%', global_cvr * 100), ' ',
      '(+', FORMAT('%.1f%%', cvr_pct_change), ' vs Woowa)',
      IF(cvr_stat_sig = 'Yes', ' ✓ sig', '')
    ) AS alert_message,
    'POSITIVE' AS alert_level,
    3 AS sort_order
  FROM query_comparison
  WHERE global_searches >= 20
    AND cvr_pct_change > 15
    AND cvr_stat_sig = 'Yes'
  ORDER BY cvr_pct_change DESC
  LIMIT 5

  UNION ALL

  -- Top Degrading Queries
  SELECT
    'DEGRADING_QUERIES' AS section,
    search_query AS detail,
    CONCAT(
      'Query: "', search_query, '" - ',
      CAST(global_searches AS STRING), ' searches, ',
      'CVR: ', FORMAT('%.1f%%', global_cvr * 100), ' ',
      '(', FORMAT('%.1f%%', cvr_pct_change), ' vs Woowa)',
      IF(cvr_stat_sig = 'Yes', ' ✓ sig', '')
    ) AS alert_message,
    CASE
      WHEN cvr_stat_sig = 'Yes' AND cvr_pct_change < -20 THEN 'CRITICAL'
      WHEN cvr_stat_sig = 'Yes' THEN 'WARNING'
      ELSE 'INFO'
    END AS alert_level,
    4 AS sort_order
  FROM query_comparison
  WHERE global_searches >= 20
    AND cvr_pct_change < -10
  ORDER BY cvr_pct_change ASC
  LIMIT 10

  UNION ALL

  -- Session Analysis
  SELECT
    'SESSION_ANALYSIS' AS section,
    account_id_group AS detail,
    CONCAT(
      account_id_group, ': ',
      CAST(total_sessions AS STRING), ' sessions, ',
      CAST(total_searches AS STRING), ' searches, ',
      FORMAT('%.2f', searches_per_session), ' searches/session'
    ) AS alert_message,
    'INFO' AS alert_level,
    5 AS sort_order
  FROM session_analysis

  UNION ALL

  -- NULL Vertical Alert (if significant change)
  SELECT
    'NULL_VERTICAL_ALERT' AS section,
    'NULL_VERTICAL' AS detail,
    CONCAT(
      'NULL vertical performance: ',
      'CVR: ', FORMAT('%.1f%%', global_cvr * 100), ' ',
      '(', IF(cvr_pct_change > 0, '+', ''), FORMAT('%.1f%%', cvr_pct_change), ' vs Woowa), ',
      CAST(global_searches AS STRING), ' searches'
    ) AS alert_message,
    CASE
      WHEN cvr_stat_sig = 'Yes' AND cvr_pct_change < -5 THEN 'WARNING'
      ELSE 'INFO'
    END AS alert_level,
    6 AS sort_order
  FROM overall_comparison
  WHERE search_vertical = 'NULL_VERTICAL'
    AND global_searches IS NOT NULL
)

-- Final formatted report
SELECT
  FORMAT_TIMESTAMP('%Y-%m-%d', TIMESTAMP(report_date)) AS report_date,
  section,
  detail,
  alert_message,
  alert_level
FROM formatted_report
ORDER BY sort_order,
  CASE alert_level
    WHEN 'CRITICAL' THEN 1
    WHEN 'WARNING' THEN 2
    WHEN 'POSITIVE' THEN 3
    WHEN 'INFO' THEN 4
  END,
  detail;
