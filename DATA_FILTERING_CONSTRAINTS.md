# Data Filtering Constraints - Woowa Search Analysis

## Overview
This document outlines the data filtering and cleanup rules applied to ensure we analyze only valid search traffic. The Woowa team should apply the same filters for consistency.

---

## 1. NULL Vertical Exclusion

### What We Exclude
All events where `search_vertical` (or `searchVerticalName`) is **NULL**.

### Why We Exclude It
NULL vertical represents **non-search traffic**:
- **Browsing** restaurant lists (FOOD_SHOP_LIST screen - 81%)
- **Favorites** page views (FAVORITE screen - 16%)
- Other navigation events (SEARCH_RESULT screen - 1.5%, but 95% don't match backend tracking)

### Evidence (from May 28, 2026 data)
- 242,927 `shop_list.updated` events with NULL vertical
- **0 had searchTrackingId** (no search tracking)
- **0 had searchTerm** (no search query)
- Only 205/3,766 SEARCH_RESULT events matched backend tracking (5%)

### Filter Implementation
```sql
WHERE search_vertical IN ('ALL', 'BAEMIN_DELIVERY')
-- Excludes NULL vertical (not actual search traffic - browsing/favorites)
```

---

## 2. Vertical Inclusion Rules

### What We Include
Only the following search verticals:
- **ALL**: Mixed search (delivery + takeout)
- **BAEMIN_DELIVERY**: Delivery-only search

### What We Exclude
- **BAEMIN_TAKEOUT**: Not served by Global Search
- **NULL**: Not search traffic (see Section 1)

### Filter Implementation
```sql
WHERE search_vertical IN ('ALL', 'BAEMIN_DELIVERY')
```

---

## 3. Search Event Requirements

### Required Fields
For an event to be considered valid search traffic, it must have:
1. **searchTrackingId** (or search_request_id) - NOT NULL
2. **searchTerm** (or search_query) - NOT NULL for query-level analysis
3. **search_vertical** - Must be 'ALL' or 'BAEMIN_DELIVERY'

### Event Actions
Valid search events include:
- `shop_list.updated` - Search results displayed
- `shop.clicked` - User clicked on a restaurant
- `transaction` - User completed an order

### Filter Implementation
```sql
WHERE search_request_id IS NOT NULL
  AND eventAction IN ('shop_list.updated','shop.clicked','shop_list.expanded','transaction')
```

For query-level analysis:
```sql
WHERE search_term IS NOT NULL
```

---

## 4. Backend Tracking Join

### System Classification
We classify traffic into two groups by joining with backend tracking table:

**Global Search** (AWS-based):
```sql
CASE
  WHEN s.google_project_id LIKE 'aws-search-woowa-cell-%' 
  THEN 'aws-search-woowa-cells-combined'
  ELSE s.google_project_id
END AS account_id_group
```

**Woowa Search** (Legacy):
```sql
-- Events NOT in backend tracking table
WHERE NOT EXISTS (
  SELECT 1
  FROM `search-restaurant-stats-9826.backendtracking.vendor-v1` AS s
  WHERE s.global_entity_id = events.global_entity_id
    AND events.session_key = s.perseus_session_id
    AND events.search_request_id = s.request_id
    AND DATE(timestamp_utc) = report_date
)
```

### Join Keys
- `global_entity_id` = `s.global_entity_id`
- `session_key` = `s.perseus_session_id`
- `search_request_id` = `s.request_id`
- `DATE(eventTimestamp)` = `DATE(s.timestamp_utc)`

---

## 5. Date Filtering

### Report Date
All queries use **CURRENT_DATE()** for report date.

**Why**: Woowa is in Korea (UTC+9), ahead of most timezones. When running at 9am PST, most of Woowa's day is complete. When running at 5pm PST, Woowa's full day is done.

### Date Filter Implementation
```sql
DECLARE report_date DATE DEFAULT CURRENT_DATE();

WHERE DATE(eventTimestamp) = report_date
  AND DATE(timestamp_utc) = report_date  -- For backend tracking join
```

---

## 6. Volume Thresholds

### Query-Level Analysis
Minimum volume for inclusion in comparative analysis:

**Failing Queries**: >= 20 searches on Global Search
```sql
WHERE global_searches >= 20
```

**Improving/Degrading Queries**: >= 20 searches on Global Search
```sql
WHERE global_searches >= 20
```

**Statistical Significance**: >= 30 searches per system
```sql
WHEN ws.searches < 30 OR gs.searches < 30 THEN 'Insufficient Data'
```

### Rationale
- Below 20 searches: Too noisy for actionable insights
- Below 30 searches: Cannot reliably calculate statistical significance

---

## 7. Tier Definitions (Head/Torso/Tail)

### Unified Tier Calculation
Tiers are calculated based on **combined traffic** (Woowa + Global Search) to ensure apples-to-apples comparison.

**Head**: Top 50% of cumulative search volume
**Torso**: Next 30% of cumulative search volume  
**Tail**: Bottom 20% of cumulative search volume

### Calculation Logic
```sql
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
)
```

**Why Unified**: Prevents the same query from being in different tiers across systems, enabling fair comparison.

---

## Summary for Woowa Team

### Apply These Filters

**1. Exclude NULL vertical**
```sql
WHERE searchVerticalName IN ('ALL', 'BAEMIN_DELIVERY')
```

**2. Require search identifiers**
```sql
WHERE searchTrackingId IS NOT NULL
  AND searchTerm IS NOT NULL  -- For query-level analysis
```

**3. Use current date**
```sql
WHERE DATE(eventTimestamp) = CURRENT_DATE()
```

**4. Valid event actions**
```sql
WHERE eventAction IN ('shop_list.updated','shop.clicked','shop_list.expanded','transaction')
```

**5. Minimum volume thresholds**
- Query analysis: >= 20 searches
- Statistical tests: >= 30 searches per system

### What This Removes
- **NULL vertical**: 242K events/day (~20% of shop_list.updated events)
  - Browsing restaurant lists (81%)
  - Favorites pages (16%)
  - No search tracking, no search terms
- **BAEMIN_TAKEOUT**: Not served by Global Search
- **Low volume queries**: < 20 searches (too noisy)

### Result
Clean, comparable search traffic analysis that isolates actual search behavior from browsing/navigation.
