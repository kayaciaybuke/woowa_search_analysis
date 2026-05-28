# AB Test Analysis - Complete Filter Reference

**Purpose:** Ensure we're measuring the right users, events, and searches for valid AB test comparison.

## Filter Summary by Stage

### 1. Assignment Table Filters (`gs_woowa_assignments`)

**Location:** `assignments` CTE

```sql
WHERE assignment_date <= report_date  -- D+1 lag consideration
  AND variation IN ('A', 'B')         -- Exclude C (non-participants)
```

**What it does:**
- ✅ Only includes assignments up to the report date (respects D+1 lag)
- ✅ **A = Control** (~18K users, 50% of AB test)
- ✅ **B = Treatment** (~18K users, 50% of AB test)
- ❌ **Excludes C** (~1.77M users who are not in the AB test)

**Pre-filtered in source table:**
- ✅ App version ≥15.15 (set in assignment generation script)
- ✅ Exposure-gated: only users with ≥1 `shop_list.updated` event post-assignment
- ✅ First assignment wins (if user assigned multiple times)
- ✅ Valid decision reason: `baemin_decisionReason = 'ASSIGNMENT'`

---

### 2. Perseus Event Filters

**Location:** `events` CTE

```sql
WHERE DATE(eventTimestamp) = report_date
  AND eventAction IN ('shop_list.updated','shop.clicked','shop_list.expanded','transaction')
  AND clientId IS NOT NULL
```

**What it does:**
- ✅ Only yesterday's events (D+1 lag for assignments)
- ✅ Only relevant search events:
  - `shop_list.updated` — Search results displayed
  - `shop.clicked` — User clicked a shop
  - `shop_list.expanded` — User paginated (saw more results)
  - `transaction` — User completed an order
- ✅ Must have clientId (required for joining with assignments)

**Excluded events:**
- ❌ Events without clientId (can't attribute to AB test)
- ❌ Non-search events (browsing, favorites, etc.)
- ❌ Events before/after the report date

---

### 3. Join Conditions & Post-Assignment Filter

**Location:** `assigned_events` CTE

```sql
INNER JOIN assignments a
  ON e.client_id = a.client_id
WHERE e.eventTimestamp >= a.assignment_timestamp
```

**What it does:**
- ✅ **INNER JOIN**: Only events from users who have assignments (A or B)
- ✅ **Post-assignment only**: Events must occur AFTER user was assigned
- ✅ Prevents pre-assignment contamination

**Excluded:**
- ❌ Events from users not in AB test (no assignment)
- ❌ Events from variation C (non-participants)
- ❌ Events that occurred before the user was assigned

**Note:** `global_entity_id` join removed as redundant (all are 'BM_KR')

---

### 4. Search Request Filters

**Location:** `search_grain` CTE

```sql
WHERE search_request_id IS NOT NULL
```

**What it does:**
- ✅ Only events that have a search tracking ID
- ✅ Ensures we're measuring actual searches (not browsing)

**Excluded:**
- ❌ Events without `searchTrackingId` (browsing, favorites)
- ❌ NULL vertical events (not search traffic - see investigation)

---

### 5. Search Vertical Filters

**Location:** Throughout query (search_grain, query_metrics, etc.)

```sql
WHERE search_vertical IN ('ALL', 'BAEMIN_DELIVERY')
```

**What it does:**
- ✅ **ALL** — Mixed results tab (all vendor types)
- ✅ **BAEMIN_DELIVERY** — Delivery-only results tab

**Excluded:**
- ❌ **NULL_VERTICAL** — Not search traffic (browsing/favorites)
  - Evidence: 242K events/day, 0 have searchTrackingId
  - See `sample_null_vertical_request.sql` for investigation
- ❌ **BAEMIN_TAKEOUT** — Pickup tab (not in AB test scope)

---

### 6. Query-Specific Filters

#### Comprehensive Query Only

**Location:** Final `query_comparison` CTE

```sql
WHERE treatment.searches >= 5  -- Only queries with meaningful Treatment volume
```

**What it does:**
- ✅ Removes low-volume noise from detailed query breakdown
- ✅ Focuses on queries with statistical validity

**Note:** Not applied to overall or tier queries (aggregate level is fine)

---

## Complete Filter Chain (Step-by-Step)

### Starting Point
- **Perseus events**: 2B+ events/day (all Korea)
- **Assignments**: 1.8M total (36K in A+B)

### Step 1: Filter Assignments
```sql
1.8M assignments
  → Filter: variation IN ('A', 'B')
  → Filter: assignment_date <= report_date
Result: ~36K AB test participants
```

### Step 2: Filter Perseus Events
```sql
2B+ events/day
  → Filter: DATE(eventTimestamp) = report_date
  → Filter: eventAction IN (shop_list.updated, shop.clicked, shop_list.expanded, transaction)
  → Filter: clientId IS NOT NULL
Result: ~8M search-related events/day
```

### Step 3: Join & Post-Assignment Filter
```sql
~8M events + ~36K assignments
  → INNER JOIN on clientId
  → Filter: eventTimestamp >= assignment_timestamp
Result: ~500K assigned events (from AB test users only)
```

### Step 4: Search-Level Filters
```sql
~500K assigned events
  → Filter: search_request_id IS NOT NULL
  → Group by search_request_id (one row per search)
Result: ~300-400 searches/day in AB test
```

### Step 5: Vertical Filter
```sql
~300-400 searches
  → Filter: search_vertical IN ('ALL', 'BAEMIN_DELIVERY')
Result: ~300-400 searches (NULL_VERTICAL already excluded)
```

### Step 6: Comprehensive Query Only
```sql
~300-400 searches (per search term)
  → Filter: treatment.searches >= 5
Result: ~50-100 unique search terms with enough volume
```

---

## Key Data Quality Checks

### ✅ What We're Measuring

1. **AB Test Participants Only**
   - Users assigned to A (Control) or B (Treatment)
   - Excluding C (non-participants)

2. **Post-Assignment Events Only**
   - Events after `assignment_timestamp`
   - Prevents pre-assignment bias

3. **Actual Search Traffic Only**
   - Has `searchTrackingId`
   - Has `searchTerm` (query-level analysis)
   - Excludes browsing/favorites (NULL_VERTICAL)

4. **Relevant Search Verticals**
   - ALL (mixed results)
   - BAEMIN_DELIVERY (delivery only)
   - Excludes TAKEOUT (not in AB test scope)

5. **Yesterday's Data Only**
   - D+1 lag for assignment table refresh
   - Complete day of data

### ❌ What We're Excluding

1. **Users:**
   - Variation C (non-participants, ~1.77M)
   - Users without assignments
   - Users with app version <15.15 (filtered in assignment generation)

2. **Events:**
   - Pre-assignment events
   - Events without clientId
   - Events without searchTrackingId
   - Non-search events (browsing, favorites)

3. **Verticals:**
   - NULL_VERTICAL (not search traffic)
   - BAEMIN_TAKEOUT (not in AB test)

4. **Low-Volume Queries (Comprehensive Query Only):**
   - Queries with <5 searches in Treatment

---

## Filter Validation Queries

### Check Assignment Distribution
```sql
SELECT 
  variation,
  COUNT(*) as users,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) as pct
FROM `dhub-gd-analytics.eppo_input.gs_woowa_assignments`
WHERE assignment_date <= CURRENT_DATE() - 1
GROUP BY variation
ORDER BY users DESC;
```

**Expected:**
- A: ~18K (50% of A+B)
- B: ~18K (50% of A+B)
- C: ~1.77M (excluded)

### Check Search Vertical Distribution
```sql
-- Using yesterday's events with AB test filters
SELECT 
  search_vertical,
  COUNT(DISTINCT search_request_id) as searches
FROM assigned_events
WHERE search_request_id IS NOT NULL
GROUP BY search_vertical
ORDER BY searches DESC;
```

**Expected:**
- ALL: ~60-70% of searches
- BAEMIN_DELIVERY: ~30-40% of searches
- NULL_VERTICAL: Should be 0 (excluded)

### Check Post-Assignment Filter
```sql
-- Events before vs after assignment
WITH assignment_times AS (
  SELECT client_id, MIN(assignment_timestamp) as first_assignment
  FROM assignments
  GROUP BY client_id
)
SELECT
  'Before Assignment' as event_timing,
  COUNT(*) as events
FROM events e
JOIN assignment_times a ON e.client_id = a.client_id
WHERE e.eventTimestamp < a.first_assignment

UNION ALL

SELECT
  'After Assignment',
  COUNT(*)
FROM events e
JOIN assignment_times a ON e.client_id = a.client_id
WHERE e.eventTimestamp >= a.first_assignment;
```

**Expected:**
- Before Assignment: 0 (filtered out)
- After Assignment: All events (correct)

---

## Traffic Split Validation

### Expected Distribution
```
Control (A):     ~50% of searches
Treatment (B):   ~50% of searches
Non-participants (C): 0% (excluded)
```

### Check in Query Output
```sql
-- Look for this column in all AB test queries
treatment_traffic_pct  -- Should be ~50.0%
```

**Red flags:**
- <45% or >55%: Imbalanced traffic (investigate Eppo config)
- <40% or >60%: Significant imbalance (check assignment logic)

---

## Common Mistakes to Avoid

### ❌ Don't Do This

1. **Using 'control'/'treatment' instead of 'A'/'B'**
   ```sql
   WHERE variation = 'control'  -- WRONG (doesn't exist)
   ```

2. **Including variation C**
   ```sql
   WHERE variation IN ('A', 'B', 'C')  -- WRONG (C are non-participants)
   ```

3. **Forgetting post-assignment filter**
   ```sql
   INNER JOIN assignments a ON e.client_id = a.client_id
   -- MISSING: WHERE e.eventTimestamp >= a.assignment_timestamp
   ```

4. **Using today's data**
   ```sql
   DECLARE report_date DATE DEFAULT CURRENT_DATE();  -- WRONG (D+1 lag)
   ```

5. **Including NULL_VERTICAL**
   ```sql
   WHERE search_vertical IN ('ALL', 'BAEMIN_DELIVERY', NULL)  -- WRONG
   ```

### ✅ Do This Instead

1. Use 'A' and 'B': `WHERE variation IN ('A', 'B')`
2. Exclude C: Already done by filtering to A and B
3. Filter post-assignment: `WHERE e.eventTimestamp >= a.assignment_timestamp`
4. Use yesterday: `DECLARE report_date DATE DEFAULT CURRENT_DATE() - 1`
5. Exclude NULL: `WHERE search_vertical IN ('ALL', 'BAEMIN_DELIVERY')`

---

## Summary Table

| Filter Stage | What's Included | What's Excluded | Why |
|-------------|----------------|-----------------|-----|
| **Assignments** | A, B up to report_date | C (non-participants) | Clean AB test sample |
| **Events** | shop_list.updated, shop.clicked, shop_list.expanded, transaction | Browsing, favorites | Only search events |
| **Timing** | Events after assignment_timestamp | Events before assignment | Prevent contamination |
| **Join** | INNER JOIN on clientId | Non-assigned users | AB test participants only |
| **Search ID** | Has searchTrackingId | NULL searchTrackingId | Actual searches only |
| **Vertical** | ALL, BAEMIN_DELIVERY | NULL_VERTICAL, TAKEOUT | AB test scope |
| **Volume** | treatment.searches >= 5 (comprehensive only) | Low-volume queries | Statistical validity |

---

**Last Updated:** May 28, 2026  
**Query Version:** v3.0 with corrected variation mapping
