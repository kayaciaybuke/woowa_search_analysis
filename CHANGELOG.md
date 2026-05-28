# Query Changes - Latest Update

## Changes Made on May 28, 2026

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
