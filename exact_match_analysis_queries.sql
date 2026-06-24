-- =============================================================================
-- EXACT MATCH ANALYSIS FOR RESTAURANT QUERIES
-- =============================================================================
-- Purpose: Analyze restaurant-classified queries by exact match positioning
-- and track whether orders come from exact match vendors or other vendors
--
-- Date Range: 2026-05-30 to 2026-06-17 (inclusive)
-- Variation: B
-- Classification: RESTAURANT (uppercase)
-- Attribution: Last-click attribution
-- =============================================================================

-- =============================================================================
-- QUERY 1: Restaurant Queries by Exact Match Category
-- =============================================================================
-- Shows searches, orders, and CVR broken down by:
-- - rank_1: Exact match at position 1
-- - displaced: Exact match returned but not at position 1
-- - no_match: No exact match returned
-- =============================================================================

WITH assigned AS (
  SELECT
    assignment_user_id AS client_id,
    assignment_timestamp AS first_assign_ts
  FROM `dhub-gd-analytics.eppo_input.gs_woowa_assignments`
  WHERE variation = "B"
    AND DATE(assignment_timestamp) BETWEEN "2026-05-30" AND "2026-06-17"
),

events AS (
  SELECT
    eventTimestamp,
    clientId AS client_id,
    sessionId AS session_key,
    JSON_VALUE(eventVariablesJson, "$.searchTrackingId") AS search_request_id,
    eventAction AS event_name
  FROM `fulfillment-dwh-production.curated_data_shared_data_stream_perseus.baemin_korea_perseus`
  WHERE DATE(eventTimestamp) BETWEEN "2026-05-30" AND "2026-06-17"
    AND eventAction IN ("shop_list.updated", "shop.clicked", "transaction")
    AND clientId IS NOT NULL
),

assigned_events AS (
  SELECT e.*
  FROM events e
  INNER JOIN assigned a ON e.client_id = a.client_id
  WHERE e.eventTimestamp >= a.first_assign_ts
),

searches AS (
  SELECT DISTINCT
    search_request_id,
    session_key,
    client_id
  FROM assigned_events
  WHERE event_name = "shop_list.updated"
    AND search_request_id IS NOT NULL
),

restaurant_exact_match AS (
  SELECT
    request_id,
    MIN(vendor.final_rank) AS best_exact_match_rank
  FROM `search-restaurant-stats-9826.backendtracking.vendor-v1`,
       UNNEST(results.vendors.items) AS vendor
  WHERE DATE(timestamp_utc) BETWEEN "2026-05-30" AND "2026-06-17"
    AND ranking.request.query_classification = "RESTAURANT"
    AND vendor.is_exact_match = TRUE
  GROUP BY request_id
),

restaurant_all AS (
  SELECT DISTINCT request_id
  FROM `search-restaurant-stats-9826.backendtracking.vendor-v1`
  WHERE DATE(timestamp_utc) BETWEEN "2026-05-30" AND "2026-06-17"
    AND ranking.request.query_classification = "RESTAURANT"
),

restaurant_searches AS (
  SELECT
    s.search_request_id,
    s.session_key,
    s.client_id,
    CASE
      WHEN e.best_exact_match_rank = 1 THEN "rank_1"
      WHEN e.best_exact_match_rank > 1 THEN "displaced"
      ELSE "no_match"
    END AS exact_match_category
  FROM searches s
  INNER JOIN restaurant_all r ON s.search_request_id = r.request_id
  LEFT JOIN restaurant_exact_match e ON s.search_request_id = e.request_id
),

clicks AS (
  SELECT
    search_request_id,
    session_key,
    client_id,
    eventTimestamp AS click_time
  FROM assigned_events
  WHERE event_name = "shop.clicked"
    AND search_request_id IS NOT NULL
),

transactions AS (
  SELECT
    session_key,
    client_id,
    eventTimestamp AS tx_time
  FROM assigned_events
  WHERE event_name = "transaction"
),

last_clicks AS (
  SELECT
    c.search_request_id AS last_click_search_id
  FROM transactions t
  INNER JOIN clicks c
    ON t.session_key = c.session_key
    AND t.client_id = c.client_id
    AND c.click_time < t.tx_time
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY t.session_key, t.client_id, t.tx_time
    ORDER BY c.click_time DESC
  ) = 1
),

search_performance AS (
  SELECT
    s.exact_match_category,
    s.search_request_id,
    CASE WHEN l.last_click_search_id IS NOT NULL THEN 1 ELSE 0 END AS had_order
  FROM restaurant_searches s
  LEFT JOIN last_clicks l ON s.search_request_id = l.last_click_search_id
)

SELECT
  exact_match_category,
  COUNT(*) AS searches,
  SUM(had_order) AS orders,
  ROUND(100.0 * SUM(had_order) / COUNT(*), 2) AS cvr_pct
FROM search_performance
GROUP BY exact_match_category
ORDER BY
  CASE exact_match_category
    WHEN "rank_1" THEN 1
    WHEN "displaced" THEN 2
    WHEN "no_match" THEN 3
  END;


-- =============================================================================
-- QUERY 2: Order Source Analysis (Exact Match Vendor vs Other Vendors)
-- =============================================================================
-- For rank_1 and displaced categories, breaks down whether orders came from:
-- - The exact match vendor
-- - Other vendors in the results
--
-- Key Fields:
-- - exact_match_cvr_pct: CVR from exact match vendor only
-- - other_vendor_cvr_pct: CVR from all other vendors
-- - pct_orders_from_exact_match: % of orders from exact match vendor
-- =============================================================================

WITH assigned AS (
  SELECT
    assignment_user_id AS client_id,
    assignment_timestamp AS first_assign_ts
  FROM `dhub-gd-analytics.eppo_input.gs_woowa_assignments`
  WHERE variation = "B"
    AND DATE(assignment_timestamp) BETWEEN "2026-05-30" AND "2026-06-17"
),

events AS (
  SELECT
    eventTimestamp,
    clientId AS client_id,
    sessionId AS session_key,
    JSON_VALUE(eventVariablesJson, "$.searchTrackingId") AS search_request_id,
    JSON_VALUE(eventVariablesJson, "$.shopId") AS shop_id,
    eventAction AS event_name
  FROM `fulfillment-dwh-production.curated_data_shared_data_stream_perseus.baemin_korea_perseus`
  WHERE DATE(eventTimestamp) BETWEEN "2026-05-30" AND "2026-06-17"
    AND eventAction IN ("shop_list.updated", "shop.clicked", "transaction")
    AND clientId IS NOT NULL
),

assigned_events AS (
  SELECT e.*
  FROM events e
  INNER JOIN assigned a ON e.client_id = a.client_id
  WHERE e.eventTimestamp >= a.first_assign_ts
),

searches AS (
  SELECT DISTINCT
    search_request_id,
    session_key,
    client_id
  FROM assigned_events
  WHERE event_name = "shop_list.updated"
    AND search_request_id IS NOT NULL
),

exact_match_vendors AS (
  SELECT
    request_id,
    vendor.id AS exact_match_vendor_id,
    vendor.final_rank AS exact_match_rank
  FROM `search-restaurant-stats-9826.backendtracking.vendor-v1`,
       UNNEST(results.vendors.items) AS vendor
  WHERE DATE(timestamp_utc) BETWEEN "2026-05-30" AND "2026-06-17"
    AND ranking.request.query_classification = "RESTAURANT"
    AND vendor.is_exact_match = TRUE
),

best_exact_match AS (
  SELECT
    request_id,
    MIN(exact_match_rank) AS best_rank
  FROM exact_match_vendors
  GROUP BY request_id
),

restaurant_all AS (
  SELECT DISTINCT request_id
  FROM `search-restaurant-stats-9826.backendtracking.vendor-v1`
  WHERE DATE(timestamp_utc) BETWEEN "2026-05-30" AND "2026-06-17"
    AND ranking.request.query_classification = "RESTAURANT"
),

restaurant_searches AS (
  SELECT
    s.search_request_id,
    s.session_key,
    s.client_id,
    CASE
      WHEN b.best_rank = 1 THEN "rank_1"
      WHEN b.best_rank > 1 THEN "displaced"
      ELSE "no_match"
    END AS exact_match_category,
    ARRAY_AGG(DISTINCT e.exact_match_vendor_id IGNORE NULLS) AS exact_match_vendor_ids
  FROM searches s
  INNER JOIN restaurant_all r ON s.search_request_id = r.request_id
  LEFT JOIN best_exact_match b ON s.search_request_id = b.request_id
  LEFT JOIN exact_match_vendors e ON s.search_request_id = e.request_id
  GROUP BY s.search_request_id, s.session_key, s.client_id, exact_match_category
),

clicks AS (
  SELECT
    search_request_id,
    session_key,
    client_id,
    shop_id,
    eventTimestamp AS click_time
  FROM assigned_events
  WHERE event_name = "shop.clicked"
    AND search_request_id IS NOT NULL
    AND shop_id IS NOT NULL
),

transactions AS (
  SELECT
    session_key,
    client_id,
    eventTimestamp AS tx_time
  FROM assigned_events
  WHERE event_name = "transaction"
),

last_clicks AS (
  SELECT
    t.session_key,
    t.client_id,
    c.search_request_id AS last_click_search_id,
    c.shop_id AS ordered_shop_id
  FROM transactions t
  INNER JOIN clicks c
    ON t.session_key = c.session_key
    AND t.client_id = c.client_id
    AND c.click_time < t.tx_time
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY t.session_key, t.client_id, t.tx_time
    ORDER BY c.click_time DESC
  ) = 1
),

search_performance AS (
  SELECT
    s.exact_match_category,
    s.search_request_id,
    CASE WHEN l.last_click_search_id IS NOT NULL THEN 1 ELSE 0 END AS had_order,
    CASE
      WHEN l.ordered_shop_id IS NOT NULL
           AND l.ordered_shop_id IN UNNEST(s.exact_match_vendor_ids)
      THEN 1
      ELSE 0
    END AS order_from_exact_match
  FROM restaurant_searches s
  LEFT JOIN last_clicks l ON s.search_request_id = l.last_click_search_id
  WHERE s.exact_match_category IN ("rank_1", "displaced")
)

SELECT
  exact_match_category,
  COUNT(*) AS searches,
  SUM(had_order) AS total_orders,
  SUM(order_from_exact_match) AS orders_from_exact_match,
  SUM(had_order) - SUM(order_from_exact_match) AS orders_from_other_vendors,
  ROUND(100.0 * SUM(had_order) / COUNT(*), 2) AS overall_cvr_pct,
  ROUND(100.0 * SUM(order_from_exact_match) / COUNT(*), 2) AS exact_match_cvr_pct,
  ROUND(100.0 * (SUM(had_order) - SUM(order_from_exact_match)) / COUNT(*), 2) AS other_vendor_cvr_pct,
  ROUND(100.0 * SUM(order_from_exact_match) / NULLIF(SUM(had_order), 0), 2) AS pct_orders_from_exact_match
FROM search_performance
GROUP BY exact_match_category
ORDER BY
  CASE exact_match_category
    WHEN "rank_1" THEN 1
    WHEN "displaced" THEN 2
  END;
