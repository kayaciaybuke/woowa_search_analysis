-- =================================================================
-- RESTAURANT EXACT MATCH ANALYSIS - TREATMENT (GLOBAL SEARCH) ONLY
-- backendtracking.vendor-v1 only logs Global Search (Treatment B) traffic.
-- Control (A) = Woowa native search, no backendtracking records — excluded.
-- Three questions:
--   1. Coverage        : restaurant queries with ≥1 exact match vendor returned
--   2. Failure         : restaurant queries with 0 exact match vendors
--   3. Misclassification: classified restaurant, results exist, no exact match vendor
--
-- Position: i.final_rank from backendtracking
-- Click tracking: Perseus page-chaining (repo pattern)
-- Schema: results.vendors is STRUCT; results.vendors.items is ARRAY; vendor ID: i.id
-- =================================================================
DECLARE start_date DATE DEFAULT '2026-05-30';
DECLARE end_date DATE DEFAULT CURRENT_DATE() - 1;

WITH assignments AS (
  SELECT
    assignment_user_id AS client_id,
    variation,
    assignment_timestamp
  FROM `dhub-gd-analytics.eppo_input.gs_woowa_assignments`
  WHERE assignment_date <= end_date
    AND variation IN ('A', 'B')
),

-- All Perseus events for click tracking + request join
events AS (
  SELECT
    DATE(eventTimestamp)                                        AS partition_date,
    eventTimestamp,
    globalEntityId                                              AS global_entity_id,
    clientId                                                    AS client_id,
    sessionId                                                   AS session_key,
    JSON_VALUE(eventVariablesJson, '$.searchTrackingId')        AS search_request_id,
    eventAction                                                 AS event_name,
    JSON_VALUE(eventVariablesJson, '$.searchVerticalName')      AS search_vertical,
    JSON_VALUE(eventVariablesJson, '$.searchTerm')              AS search_term,
    JSON_VALUE(eventVariablesJson, '$.shopsIds')                AS shops_ids,
    JSON_VALUE(eventVariablesJson, '$.shopId')                  AS shop_id
  FROM `fulfillment-dwh-production.curated_data_shared_data_stream_perseus.baemin_korea_perseus`
  WHERE DATE(eventTimestamp) BETWEEN start_date AND end_date
    AND eventAction IN ('shop_list.updated', 'shop_list.expanded', 'shop.clicked', 'transaction')
    AND clientId IS NOT NULL
),

assigned_events AS (
  SELECT
    e.*,
    a.variation,
    a.assignment_timestamp
  FROM events e
  INNER JOIN assignments a
    ON e.client_id = a.client_id
  WHERE e.eventTimestamp >= a.assignment_timestamp
    AND e.search_vertical IN ('ALL', 'BAEMIN_DELIVERY')
),

-- Page-chaining position logic (from repo)
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

-- Backend tracking: summary per request (no array collection)
backend AS (
  SELECT
    s.request_id,
    s.perseus_session_id,
    s.global_entity_id,
    DATE(s.timestamp_utc)                                       AS event_date,
    s.request.query                                             AS search_term,
    query_expansion.response.query_classification               AS classification,
    EXISTS (
      SELECT 1 FROM UNNEST(s.results.vendors.items) AS i
      WHERE i.is_exact_match = TRUE
    )                                                           AS has_exact_match,
    (SELECT COUNT(*) FROM UNNEST(s.results.vendors.items) AS i
     WHERE i.is_exact_match = TRUE)                            AS n_exact_match_vendors,
    (SELECT COUNT(*) FROM UNNEST(s.results.vendors.items) AS i)
                                                                AS n_total_vendors,
    (SELECT MIN(i.final_rank) FROM UNNEST(s.results.vendors.items) AS i
     WHERE i.is_exact_match = TRUE)                            AS best_exact_match_rank
  FROM `search-restaurant-stats-9826.backendtracking.vendor-v1` s
  WHERE DATE(s.timestamp_utc) BETWEEN start_date AND end_date
    AND s.request.brand = 'baemin'
    AND s.request.query IS NOT NULL
),

-- Exact match vendor IDs (one row per vendor per request) — for click join
em_vendors AS (
  SELECT
    s.request_id,
    s.perseus_session_id,
    s.global_entity_id,
    DATE(s.timestamp_utc) AS event_date,
    i.id                  AS vendor_id
  FROM `search-restaurant-stats-9826.backendtracking.vendor-v1` s
  CROSS JOIN UNNEST(s.results.vendors.items) AS i
  WHERE DATE(s.timestamp_utc) BETWEEN start_date AND end_date
    AND s.request.brand = 'baemin'
    AND i.is_exact_match = TRUE
),

-- Did user click on an exact match vendor? (pre-joined, avoids nested aggregate)
em_click_check AS (
  SELECT
    ae.search_request_id,
    ae.variation,
    TRUE                          AS clicked_exact_match,
    MIN(sp.correct_position)      AS clicked_exact_match_position
  FROM assigned_events ae
  INNER JOIN em_vendors emv
    ON emv.perseus_session_id = ae.session_key
    AND emv.request_id         = ae.search_request_id
    AND emv.global_entity_id   = ae.global_entity_id
    AND emv.event_date         = ae.partition_date
    AND emv.vendor_id          = ae.shop_id
  LEFT JOIN shop_positions sp
    ON sp.search_request_id = ae.search_request_id
    AND sp.shop_id           = ae.shop_id
  WHERE ae.event_name = 'shop.clicked'
  GROUP BY 1, 2
),

-- Per-search grain
search_grain AS (
  SELECT
    ae.partition_date,
    ae.variation,
    ae.global_entity_id,
    ae.search_request_id,
    ANY_VALUE(ae.search_term)              AS search_term,
    ANY_VALUE(ae.search_vertical)          AS search_vertical,
    ANY_VALUE(b.classification)            AS classification,
    ANY_VALUE(b.has_exact_match)           AS has_exact_match,
    ANY_VALUE(b.n_exact_match_vendors)     AS n_exact_match_vendors,
    ANY_VALUE(b.n_total_vendors)           AS n_total_vendors,
    ANY_VALUE(b.best_exact_match_rank)     AS best_exact_match_rank,
    COALESCE(ANY_VALUE(ecc.clicked_exact_match), FALSE)       AS clicked_exact_match,
    ANY_VALUE(ecc.clicked_exact_match_position)               AS clicked_exact_match_position,
    COUNTIF(ae.event_name = 'shop.clicked') > 0              AS had_click,
    COUNTIF(ae.event_name = 'transaction')  > 0              AS had_order
  FROM assigned_events ae
  INNER JOIN backend b
    ON b.perseus_session_id = ae.session_key
    AND b.request_id        = ae.search_request_id
    AND b.global_entity_id  = ae.global_entity_id
    AND b.event_date        = ae.partition_date
  LEFT JOIN em_click_check ecc
    ON ecc.search_request_id = ae.search_request_id
    AND ecc.variation         = ae.variation
  LEFT JOIN shop_positions sp
    ON sp.search_request_id = ae.search_request_id
    AND sp.shop_id           = ae.shop_id
  WHERE ae.search_request_id IS NOT NULL
  GROUP BY 1, 2, 3, 4
),

-- Unified tiers (combined A+B volume)
combined_volume AS (
  SELECT
    search_vertical,
    search_term,
    COUNT(*) AS total_searches,
    SUM(COUNT(*)) OVER (
      PARTITION BY search_vertical
      ORDER BY COUNT(*) DESC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_searches
  FROM search_grain
  WHERE search_term IS NOT NULL
  GROUP BY search_vertical, search_term
),

tier_calc AS (
  SELECT
    search_vertical,
    search_term,
    CASE
      WHEN cumulative_searches / SUM(total_searches) OVER (PARTITION BY search_vertical) <= 0.50 THEN 'Head'
      WHEN cumulative_searches / SUM(total_searches) OVER (PARTITION BY search_vertical) <= 0.80 THEN 'Torso'
      ELSE 'Tail'
    END AS tier
  FROM combined_volume
),

-- Treatment-only aggregate (variation = 'B' only — backendtracking = Global Search)
agg AS (
  SELECT
    sg.search_vertical,
    tc.tier,
    COALESCE(sg.classification, 'unclassified')                   AS classification,
    COUNT(*)                                                      AS searches,
    COUNTIF(sg.has_exact_match)                                   AS searches_with_exact_match,
    ROUND(SAFE_DIVIDE(COUNTIF(sg.has_exact_match), COUNT(*)), 4)  AS exact_match_coverage_rate,
    COUNTIF(sg.has_exact_match AND sg.best_exact_match_rank = 1)  AS exact_match_at_rank_1,
    COUNTIF(sg.has_exact_match AND sg.best_exact_match_rank BETWEEN 2 AND 5)
                                                                  AS exact_match_at_rank_2_5,
    COUNTIF(sg.has_exact_match AND sg.best_exact_match_rank > 5)  AS exact_match_at_rank_6plus,
    ROUND(AVG(IF(sg.has_exact_match, sg.best_exact_match_rank, NULL)), 2)
                                                                  AS avg_exact_match_rank,
    COUNTIF(sg.clicked_exact_match)                               AS searches_clicked_exact_match,
    ROUND(SAFE_DIVIDE(COUNTIF(sg.clicked_exact_match), COUNTIF(sg.has_exact_match)), 4)
                                                                  AS exact_match_ctr,
    COUNTIF(sg.classification = 'restaurant' AND NOT sg.has_exact_match)
                                                                  AS n_failures,
    ROUND(SAFE_DIVIDE(
      COUNTIF(sg.classification = 'restaurant' AND NOT sg.has_exact_match),
      COUNTIF(sg.classification = 'restaurant')
    ), 4)                                                         AS failure_rate,
    COUNTIF(sg.classification = 'restaurant'
            AND NOT sg.has_exact_match
            AND sg.n_total_vendors > 0)                           AS n_misclassified,
    ROUND(SAFE_DIVIDE(
      COUNTIF(sg.classification = 'restaurant'
              AND NOT sg.has_exact_match
              AND sg.n_total_vendors > 0),
      COUNTIF(sg.classification = 'restaurant')
    ), 4)                                                         AS misclassification_rate
  FROM search_grain sg
  INNER JOIN tier_calc tc
    ON sg.search_vertical = tc.search_vertical
    AND sg.search_term    = tc.search_term
  WHERE sg.variation = 'B'
  GROUP BY 1, 2, 3
)

SELECT
  search_vertical,
  tier,
  classification,
  searches,
  searches_with_exact_match,
  exact_match_coverage_rate,
  avg_exact_match_rank,
  exact_match_at_rank_1,
  exact_match_at_rank_2_5,
  exact_match_at_rank_6plus,
  exact_match_ctr,
  failure_rate,
  n_failures,
  misclassification_rate,
  n_misclassified
FROM agg
ORDER BY
  search_vertical,
  CASE tier WHEN 'Head' THEN 1 WHEN 'Torso' THEN 2 ELSE 3 END,
  classification,
  searches DESC;
