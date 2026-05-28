# AB Test Analysis - Analyst Guide

**Quick reference for replicating the same filters in your own queries.**

---

## Filters to Apply (Copy-Paste Ready)

### 1. Assignment Table
```sql
FROM `dhub-gd-analytics.eppo_input.gs_woowa_assignments`
WHERE assignment_date <= '2026-05-27'  -- Yesterday (or your report date)
  AND variation IN ('A', 'B')          -- A=Control, B=Treatment (exclude C)
```

### 2. Perseus Events
```sql
FROM `fulfillment-dwh-production.curated_data_shared_data_stream_perseus.baemin_korea_perseus`
WHERE DATE(eventTimestamp) = '2026-05-27'  -- Yesterday
  AND clientId IS NOT NULL
  AND eventAction IN ('shop_list.updated', 'shop.clicked', 'shop_list.expanded', 'transaction')
```

### 3. Join Logic
```sql
INNER JOIN assignments a ON e.clientId = a.assignment_user_id
WHERE e.eventTimestamp >= a.assignment_timestamp  -- Post-assignment only
```

### 4. Search Filters
```sql
WHERE searchTrackingId IS NOT NULL                    -- Has search ID
  AND searchVerticalName IN ('ALL', 'BAEMIN_DELIVERY') -- Only these tabs
```

---

## Variation Mapping

| Code | Meaning | Use in Analysis? |
|------|---------|------------------|
| A | Control (baseline) | ✅ Yes |
| B | Treatment (variant) | ✅ Yes |
| C | Non-participants | ❌ No |

---

## Event Actions

| Event | What It Means | Include? |
|-------|---------------|----------|
| `shop_list.updated` | Search results shown | ✅ Yes |
| `shop.clicked` | User clicked a shop | ✅ Yes |
| `shop_list.expanded` | User paginated | ✅ Yes |
| `transaction` | User completed order | ✅ Yes |
| Everything else | Browsing, favorites, etc | ❌ No |

---

## Search Verticals

| Vertical | Description | Include? |
|----------|-------------|----------|
| `ALL` | Mixed results tab | ✅ Yes |
| `BAEMIN_DELIVERY` | Delivery tab | ✅ Yes |
| `NULL` | Old Woowa (not search) | ❌ No |
| `BAEMIN_TAKEOUT` | Pickup tab | ❌ No |

---

## Date Rules

**Use yesterday's data only:**
```sql
DECLARE report_date DATE DEFAULT CURRENT_DATE() - 1;
```

**Why?**
- Assignment table refreshes daily (D+1 lag)
- Using today = incomplete assignments = wrong results

---

## Full Example Query

```sql
DECLARE report_date DATE DEFAULT CURRENT_DATE() - 1;

-- 1. Get assignments
WITH assignments AS (
  SELECT 
    assignment_user_id,
    variation,
    assignment_timestamp
  FROM `dhub-gd-analytics.eppo_input.gs_woowa_assignments`
  WHERE assignment_date <= report_date
    AND variation IN ('A', 'B')
),

-- 2. Get events
events AS (
  SELECT
    clientId,
    eventTimestamp,
    JSON_VALUE(eventVariablesJson, '$.searchTrackingId') AS searchTrackingId,
    JSON_VALUE(eventVariablesJson, '$.searchVerticalName') AS searchVertical,
    eventAction
  FROM `fulfillment-dwh-production.curated_data_shared_data_stream_perseus.baemin_korea_perseus`
  WHERE DATE(eventTimestamp) = report_date
    AND clientId IS NOT NULL
    AND eventAction IN ('shop_list.updated', 'shop.clicked', 'transaction')
),

-- 3. Join and filter
assigned_events AS (
  SELECT e.*, a.variation
  FROM events e
  INNER JOIN assignments a ON e.clientId = a.assignment_user_id
  WHERE e.eventTimestamp >= a.assignment_timestamp
)

-- 4. Analyze
SELECT
  variation,
  searchVertical,
  COUNT(DISTINCT searchTrackingId) AS searches
FROM assigned_events
WHERE searchTrackingId IS NOT NULL
  AND searchVertical IN ('ALL', 'BAEMIN_DELIVERY')
GROUP BY 1, 2
ORDER BY 1, 2;
```

---

## Quick Checks

### Check 1: Traffic Split (~50/50)
```sql
SELECT 
  variation,
  COUNT(*) AS users,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) AS pct
FROM `dhub-gd-analytics.eppo_input.gs_woowa_assignments`
WHERE variation IN ('A', 'B')
GROUP BY variation;
```
**Expected:** A = 50%, B = 50%

### Check 2: Only A and B
```sql
SELECT DISTINCT variation
FROM your_results_table;
```
**Expected:** Only 'A' and 'B' (no 'C')

### Check 3: Post-Assignment Only
```sql
-- Should return 0 rows
SELECT COUNT(*) 
FROM assigned_events
WHERE eventTimestamp < assignment_timestamp;
```
**Expected:** 0 rows

---

## Common Mistakes

❌ **Don't:**
- Use `variation = 'control'` (use `'A'`)
- Use `variation = 'treatment'` (use `'B'`)
- Include variation `'C'` (non-participants)
- Use `CURRENT_DATE()` (use `CURRENT_DATE() - 1`)
- Include `NULL` vertical
- Include `BAEMIN_TAKEOUT`
- Skip `eventTimestamp >= assignment_timestamp` filter

✅ **Do:**
- Filter to `variation IN ('A', 'B')`
- Use yesterday's date (`CURRENT_DATE() - 1`)
- Filter to `searchVertical IN ('ALL', 'BAEMIN_DELIVERY')`
- Require `searchTrackingId IS NOT NULL`
- Filter `eventTimestamp >= assignment_timestamp`

---

## Column Names Reference

**In assignment table:**
- `assignment_user_id` = clientId from Perseus
- `variation` = 'A', 'B', or 'C'
- `assignment_timestamp` = when user was assigned
- `assignment_date` = date of assignment (partition key)

**In Perseus:**
- `clientId` = user identifier
- `eventTimestamp` = when event occurred
- `eventVariablesJson` = JSON with search data
  - `$.searchTrackingId` = search identifier
  - `$.searchVerticalName` = which tab (ALL, BAEMIN_DELIVERY, etc)
  - `$.searchTerm` = what user searched for

---

## Traffic Split Formula

```sql
-- Add this to your results
ROUND(
  SAFE_DIVIDE(
    COUNT_IF(variation = 'B'),
    COUNT_IF(variation = 'A') + COUNT_IF(variation = 'B')
  ) * 100, 
  1
) AS treatment_traffic_pct
```

**Expected:** ~50.0%

---

**Questions?** See full queries in `woowa_search_analysis/` folder
