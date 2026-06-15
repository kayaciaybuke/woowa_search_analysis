-- Check exact field names in results.vendors.items
-- Run this first to confirm vendor ID field name before running exact match query
SELECT
  v.vendor_id,   -- try this
  i.vendor_id    AS item_vendor_id,  -- try this
  i.is_exact_match,
  TO_JSON_STRING(i) AS item_json_sample  -- shows all fields in items struct
FROM `search-restaurant-stats-9826.backendtracking.vendor-v1` s
CROSS JOIN UNNEST(s.results.vendors) AS v
CROSS JOIN UNNEST(v.items) AS i
WHERE DATE(s.timestamp_utc) = CURRENT_DATE() - 1
  AND s.request.brand = 'baemin'
  AND i.is_exact_match = TRUE
LIMIT 10;
