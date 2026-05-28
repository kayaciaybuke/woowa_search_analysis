# NULL Vertical Cleanup - Quick Summary

## The Problem
NULL vertical events (242K/day) were included in search analysis but are **NOT search traffic**:
- 0 have searchTrackingId
- 0 have searchTerm
- 81% FOOD_SHOP_LIST screen (browsing)
- 16% FAVORITE screen (favorites)
- Only 5% of SEARCH_RESULT events even match backend tracking

**Conclusion**: NULL vertical = browsing/favorites, not search.

---

## The Fix
Excluded NULL vertical from all 4 main queries:
1. comprehensive_comparison_query.sql
2. overall_comparison_query.sql
3. head_torso_tail_comparison_query.sql
4. daily_alert_report_query.sql

**Filter applied**:
```sql
WHERE search_vertical IN ('ALL', 'BAEMIN_DELIVERY')
-- Exclude NULL vertical (browsing/favorites)
```

---

## For Woowa Team
Apply these same filters for consistency:

```sql
-- 1. Exclude NULL vertical
WHERE searchVerticalName IN ('ALL', 'BAEMIN_DELIVERY')

-- 2. Require search identifiers
AND searchTrackingId IS NOT NULL
AND searchTerm IS NOT NULL  -- For query-level analysis
```

**Why**: Ensures we compare search vs search, not search vs browsing.

---

## Impact
- **Before**: 242K non-search events inflating volume and CVR
- **After**: Clean search traffic only, accurate metrics

**Detailed docs**: 
- `DATA_FILTERING_CONSTRAINTS.md` - Full filter specifications
- `DATA_CLEANUP_SUMMARY.md` - Detailed cleanup explanation
