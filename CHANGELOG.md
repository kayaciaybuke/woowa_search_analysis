# Query Changes - Latest Update

## Changes Made on June 24, 2026 (v3.1 - Date Standardization & Documentation Cleanup)

### 🔧 STANDARDIZED: Fixed Date Ranges Across All AB Test Queries

**Issue:** AB test queries used dynamic dates (CURRENT_DATE() - 1, CURRENT_DATE() - 14) which caused inconsistent analysis windows.

**Solution:** Standardized all AB test queries to use the same fixed date range:
- **Start Date:** May 30, 2026 (AB test launch)
- **End Date:** June 17, 2026 (inclusive, last complete day)

**Files Updated:**
1. `overall_comparison_query_ab_test.sql`
2. `head_torso_tail_comparison_query_ab_test.sql`
3. `comprehensive_comparison_query_ab_test.sql`
4. `query_classification_breakdown_ab_test.sql`

**Why This Matters:**
- ✅ Consistent analysis window across all queries
- ✅ Reproducible results (same date range every time)
- ✅ Aligns with exact match analysis date range
- ✅ Easier to compare results across different query types

---

### 🆕 NEW: Exact Match Analysis Queries Added

**New File:** `exact_match_analysis_queries.sql`

**What It Does:**
- Analyzes restaurant queries by exact match positioning (rank_1, displaced, no_match)
- Tracks order attribution (exact match vendor vs other vendors)
- Uses last-click attribution model
- Fixed date range: May 30 - June 17, 2026

**Key Findings Documented:**
- 95.1% of rank_1 orders come from the exact match vendor
- Displacement causes 86% CVR drop (21.68% → 3.05%)
- Exact match at position 1 has 21.68% CVR

**New Guide:** `EXACT_MATCH_ANALYSIS_GUIDE.md`
- Methodology explanation
- Technical notes on vendor ID matching
- Key findings and insights

---

### 🧹 CLEANUP: Documentation Consolidation

**Files Removed (Redundant/Temporary):**
1. `CLICK_POSITION_TRACKING_HACK.md` - Superseded by updated version
2. `CLEANUP_SUMMARY_SHORT.md` - Temporary summary of completed work
3. `DATA_CLEANUP_SUMMARY.md` - Temporary summary of completed work
4. `AB_TEST_FIX_SUMMARY.md` - Temporary summary of completed work
5. `AB_TEST_FILTERS_SUMMARY.md` - Redundant with AB_TEST_QUICK_START.md
6. `AB_TEST_FILTERS_REFERENCE.md` - Redundant with AB_TEST_QUICK_START.md
7. `AB_TEST_ANALYST_GUIDE.md` - Redundant with AB_TEST_QUICK_START.md
8. `woowa_search_query_guide.md` - Redundant with README.md
9. `QUERY_COMPARISON.md` - Redundant
10. `UNIFIED_TIERS_EXPLAINED.md` - Redundant with HEAD_TORSO_TAIL_GUIDE.md

**File Renamed:**
- `CLICK_POSITION_TRACKING_HACK_UPDATED.md` → `CLICK_POSITION_TRACKING_HACK.md`

**README.md Updated:**
- Removed references to deleted files
- Updated date range information (fixed May 30 - June 17, 2026)
- Added DATA_FILTERING_CONSTRAINTS.md to reference docs
- Updated version to v3.1

**Result:** Cleaner documentation structure with only relevant, current files.

---

## Changes Made on May 28, 2026 (v3.0 - AB Test Support)

### 🔧 FIXED: Corrected Variation Values (Critical Fix)

**Issue:** Initial AB test queries used wrong variation values ('control'/'treatment')  
**Actual values:** 'A' (Control), 'B' (Treatment), 'C' (Non-participants)

**Changes made:**
1. Updated all WHERE clauses: `variation = 'control'` → `variation = 'A'`
2. Updated all WHERE clauses: `variation = 'treatment'` → `variation = 'B'`  
3. Added filter: `WHERE variation IN ('A', 'B')` to exclude C (non-participants)

**Variation Distribution:**
- **A = Control**: ~18K users (~50% of AB test participants)
- **B = Treatment**: ~18K users (~50% of AB test participants)
- **C = Non-participants**: ~1.77M users (not in AB test, excluded)

**Files updated:**
- `overall_comparison_query_ab_test.sql`
- `head_torso_tail_comparison_query_ab_test.sql`
- `comprehensive_comparison_query_ab_test.sql`
- `AB_TEST_QUICK_START.md`
- `workflows/woowa-ab-test-analysis.md`

**Testing:** Queries now return data with ~50/50 traffic split between A and B ✅

---

### 🆕 NEW: AB Test Analysis Queries Added

**Three new queries for Control vs Treatment comparison:**
1. `overall_comparison_query_ab_test.sql` - AB test overall summary
2. `head_torso_tail_comparison_query_ab_test.sql` - AB test by tier
3. `comprehensive_comparison_query_ab_test.sql` - AB test per search query

**Key Features:**
- ✅ **Eppo assignment integration** - Uses `dhub-gd-analytics.eppo_input.gs_woowa_assignments`
- ✅ **D+1 lag support** - Designed for yesterday's data (assignment table has D+1 refresh)
- ✅ **Exposure gating** - Only assigned users with post-assignment events
- ✅ **Post-assignment filtering** - `eventTimestamp >= assignment_timestamp`
- ✅ **Unified tiers** - Tiers calculated on combined Control + Treatment volume
- ✅ **Traffic split validation** - Shows `treatment_traffic_pct` (should be ~50%)
- ✅ **Statistical significance** - Same z-test as platform comparison queries

**Assignment Table Structure:**
```sql
Table: dhub-gd-analytics.eppo_input.gs_woowa_assignments
Source: /Users/k.musina/Desktop/analytics/gs_woowa_eppo_assignments.sql
Key columns:
  - assignment_user_id (clientId from Perseus)
  - variation ('control' or 'treatment')
  - assignment_timestamp (when user was assigned)
  - assignment_date (partition key, KST timezone)
  - global_entity_id ('BM_KR')
```

**Join Logic:**
```sql
-- 1. Get assignments up to report date (respects D+1 lag)
WHERE assignment_date <= report_date

-- 2. Join with Perseus events on clientId
ON e.client_id = a.assignment_user_id

-- 3. Only events AFTER assignment
WHERE e.eventTimestamp >= a.assignment_timestamp
```

**Important Differences from Platform Comparison:**
- Uses **single report_date** (not start_date/end_date range)
- **Must use yesterday's data** (D+1 lag for assignments)
- **Excludes NULL_VERTICAL** (AB test only covers ALL, BAEMIN_DELIVERY)
- **INNER JOIN** with assignments (only assigned users)
- **Traffic split metric** (treatment_traffic_pct)

**Documentation Added:**
- `AB_TEST_QUICK_START.md` - Complete AB test guide
- Updated `README.md` - AB test vs platform comparison decision tree
- Updated workflow: `/Users/aybueke.kayaci/dh-pm-claude-skills/workflows/woowa-ab-test-analysis.md`

---

## Changes Made on May 28, 2026 (v2.0 - Data Cleanup)

### 1. ✅ CRITICAL: Exclude NULL Vertical (NOT Search Traffic)
**What:** Changed vertical filter from:
```sql
-- OLD (INCORRECT):
AND (sg.search_vertical IN ('ALL', 'BAEMIN_DELIVERY') OR sg.search_vertical IS NULL)

-- NEW (CORRECT):
AND sg.search_vertical IN ('ALL', 'BAEMIN_DELIVERY')
-- Exclude NULL vertical (not actual search traffic - browsing/favorites)
```

**Why:** Investigation revealed NULL vertical is **NOT search traffic**:
- 242,927 events/day with NULL vertical
- **0 have searchTrackingId** (no search tracking)
- **0 have searchTerm** (no search query)
- 81% FOOD_SHOP_LIST screen (browsing restaurant lists)
- 16% FAVORITE screen (viewing favorites)
- Only 5% of SEARCH_RESULT events even match backend tracking

**Impact:** 
- Removed ~242K non-search events/day from analysis
- Clean search-only metrics (no browsing contamination)
- Accurate CVR (no inflated conversion from favorites)
- Fair Woowa vs Global Search comparison

**Evidence:** See `sample_null_vertical_request.sql` for investigation query

---

### 2. ✅ All Queries Updated with Clean Filters

**Files Updated:**
1. comprehensive_comparison_query.sql
2. overall_comparison_query.sql
3. head_torso_tail_comparison_query.sql
4. daily_alert_report_query.sql

**Consistent Filters Applied:**
- Exclude NULL vertical
- Only ALL and BAEMIN_DELIVERY verticals
- Exclude BAEMIN_TAKEOUT (not served by Global Search)

---

### 3. ✅ Unified Tier Definitions (Head/Torso/Tail)

**What:** Changed from separate per-system tiers to unified tiers based on combined volume

**Before (WRONG):**
- "pizza" = Head tier in Woowa Search (high volume)
- "pizza" = Torso tier in Global Search (lower volume)
- Cannot compare apples to apples

**After (CORRECT):**
- Tiers calculated on combined traffic (Woowa + Global)
- Same query = same tier in both systems
- Apples-to-apples comparison

**Tier Definitions:**
- **Head**: Top 50% of cumulative search volume
- **Torso**: Next 30% of cumulative search volume (50-80%)
- **Tail**: Bottom 20% of cumulative search volume (80-100%)

**See:** `UNIFIED_TIERS_EXPLAINED.md` for detailed explanation

---

### 4. ✅ Date Changed to CURRENT_DATE()

**What:** Changed from `CURRENT_DATE() - 1` to `CURRENT_DATE()`

**Why:** Woowa is in Korea (UTC+9), ahead of most timezones
- Running at 9am PST = most of Woowa's day is done
- Running at 5pm PST = Woowa's full day is complete

**Impact:** Timely reporting with near-complete daily data

---

### 5. ✅ Daily Alert Report Added

**New File:** `daily_alert_report_query.sql`

**What It Monitors:**
- Overall CVR changes (statistically significant)
- Failing queries (high ZRR, low CTR on Global Search)
- Improving queries (CVR increases vs Woowa)
- Degrading queries (CVR drops vs Woowa)
- Session analysis (searches per session)

**Alert Levels:**
- CRITICAL: CVR drop >10% (stat sig)
- WARNING: CVR drop 5-10% (stat sig) OR ZRR >20%
- POSITIVE: CVR improvement >10% (stat sig)
- INFO: Normal/monitoring

**See:** `DAILY_REPORT_GUIDE.md` for response playbooks

---

## Search Verticals Now Included:

| Vertical | Description | Included? | Reason |
|----------|-------------|-----------|--------|
| ALL | Mixed Results Tab | ✅ Yes | Served by Global Search |
| BAEMIN_DELIVERY | Delivery Results Tab | ✅ Yes | Served by Global Search |
| NULL | Browsing/Favorites | ❌ **NO** | **NOT search traffic** |
| BAEMIN_TAKEOUT | Pickup Results Tab | ❌ No | Not served by Global Search |

---

## Data Quality Improvements:

### Before Cleanup:
- 242K non-search events/day included
- Inflated CVR from browsing/favorites traffic
- Misleading comparisons (search vs browsing)
- Same query in different tiers per system

### After Cleanup:
- Only actual search traffic (has searchTrackingId)
- Accurate search CVR
- Fair search vs search comparison
- Unified tiers for apples-to-apples analysis

---

## Filter Constraints for Woowa Team:

To replicate our analysis, apply these filters:

```sql
-- 1. Exclude NULL vertical
WHERE searchVerticalName IN ('ALL', 'BAEMIN_DELIVERY')

-- 2. Require search identifiers
AND searchTrackingId IS NOT NULL
AND searchTerm IS NOT NULL  -- For query-level analysis

-- 3. Valid event actions
AND eventAction IN ('shop_list.updated','shop.clicked','shop_list.expanded','transaction')

-- 4. Current date
AND DATE(eventTimestamp) = CURRENT_DATE()
```

**See:** `DATA_FILTERING_CONSTRAINTS.md` for complete specification

---

## New Documentation Files:

1. **DATA_FILTERING_CONSTRAINTS.md** - Complete filter specification with evidence
2. **DATA_CLEANUP_SUMMARY.md** - Detailed NULL vertical cleanup explanation
3. **CLEANUP_SUMMARY_SHORT.md** - Quick 1-page summary
4. **UNIFIED_TIERS_EXPLAINED.md** - Why unified tiers are better
5. **DAILY_REPORT_GUIDE.md** - Alert monitoring playbooks
6. **DAILY_AUTOMATION_UPDATE.md** - Summary of May 27 changes

---

## Query Locations:

All queries in: `/Users/aybueke.kayaci/woowa_search_analysis/`

Main queries:
- `comprehensive_comparison_query.sql` - Query-level performance
- `overall_comparison_query.sql` - Overall metrics
- `head_torso_tail_comparison_query.sql` - Tier-based analysis
- `daily_alert_report_query.sql` - Automated monitoring

---

## Last Updated:
**May 28, 2026** - NULL vertical cleanup and filter consolidation

---

## Next Steps:

1. ✅ Queries cleaned and ready
2. ✅ Documentation complete
3. ⏭️ Test queries with clean data
4. ⏭️ Share filtering constraints with Woowa team
5. ⏭️ Monitor daily alerts as test scales
