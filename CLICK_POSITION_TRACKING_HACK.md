# Click Position Tracking Hack - Documentation

## Overview
This document explains why we had to implement a workaround ("hack") for calculating accurate click positions in the Woowa search analysis, the problems we discovered in the tracking data, and the solution we applied.

---

## The Problem Discovered

### Issue 1: Position Resets by Delivery Status
**Date Discovered**: Week of May 2026 (during initial analysis setup)

**Problem**: Click positions in the tracking data (`shopPosition` field in `shop.clicked` events) reset to 0 when the vendor list transitions between delivery statuses.

**Example**:
```
Search Results Display:
Position 0-5:   Vendors with status "Delivering"
Position 0-10:  Vendors with status "Preparing"  ← Positions reset to 0!
Position 0-8:   Vendors with status "Closed"     ← Positions reset to 0 again!
```

**Impact**: 
- Cannot accurately calculate average click position
- Cannot determine if users are clicking on position 1 vs position 11 vs position 21
- Makes it impossible to measure ranking quality (e.g., "% of clicks in top 3 positions")

**Root Cause**: 
The tracking implementation groups vendors by delivery status in the UI, and positions are calculated within each status group, not across the entire result set.

**Question for Tracking Team**: Was this intentional in the tracking requirements? If not, can this be fixed at the tracking level?

---

## The Solution Applied

### Workaround: Use `shopsIds` from `shop_list.updated` Event

Instead of relying on `shopPosition` from `shop.clicked` events, we reconstruct the true position using the comma-separated list of shop IDs from `shop_list.updated` events.

### Implementation

```sql
-- Step 1: Extract shop positions from shop_list.updated + shop_list.expanded
shop_positions AS (
  SELECT
    search_request_id,
    shop_id,
    -- Each shop_list event (updated=0, expanded=1,2,3...) starts from position 0
    -- Actual position = (page_number * 25) + position_in_page
    (page_number * 25) + position as correct_position
  FROM (
    SELECT
      search_request_id,
      shops_ids,
      ROW_NUMBER() OVER (PARTITION BY search_request_id ORDER BY eventTimestamp) - 1 AS page_number
    FROM events
    WHERE event_name IN ('shop_list.updated', 'shop_list.expanded')
      AND shops_ids IS NOT NULL
  ),
  UNNEST(SPLIT(shops_ids, ',')) as shop_id WITH OFFSET as position
),

-- Step 2: Join click events with corrected positions
clicks_with_positions AS (
  SELECT
    e.partition_date,
    e.global_entity_id,
    e.session_key,
    e.search_request_id,
    sp.correct_position  -- This is the TRUE position
  FROM events e
  INNER JOIN shop_positions sp
    ON e.search_request_id = sp.search_request_id
    AND e.shop_id = sp.shop_id
  WHERE e.event_name = 'shop.clicked'
)
```

### How It Works

1. **Extract shop order from `shopsIds`**: Use `SPLIT(shopsIds, ',')` to get the ordered list of shop IDs from `shop_list.updated`
2. **Apply OFFSET**: `WITH OFFSET as position` gives each shop its position within that event (0, 1, 2, ...)
3. **Calculate page number**: Use `ROW_NUMBER() - 1` to identify which page/event (0 = first page, 1 = second page, etc.)
4. **Calculate global position**: `(page_number * 25) + position` gives the true position across all pages
5. **Join with clicks**: Match clicked shop_id with its correct global position

---

## Issue 2: Pagination Handling

### Problem: Inconsistent `searchTrackingId` in Pagination Events

**Discovery**: ~10% of `shop_list.expanded` (pagination) events have a different `searchTrackingId` than the initial `shop_list.updated` event.

**Example**:
```
User searches "pizza"
- shop_list.updated: searchTrackingId = "abc123"
- User clicks "Load More"
- shop_list.expanded: searchTrackingId = "def456"  ← Different!
```

**Question for Tracking Team**: Why do some expanded events have different `searchTrackingId`? Is this expected behavior?

### Current Approach

We still use `searchTrackingId` to group pagination events, accepting that ~10% may be miscounted:

```sql
ROW_NUMBER() OVER (PARTITION BY search_request_id ORDER BY eventTimestamp) - 1 AS page_number
```

**Alternative Considered**: Group by `(session_key, search_term)` instead of `search_request_id`, but this could incorrectly merge separate searches for the same term within a session.

---

## Open Questions & Assumptions

### ✅ Validated Assumptions

1. **`shopsIds` order matches visual display**: 
   - Checked manually by searching several queries
   - Order in `shopsIds` matches what users see on screen (with status grouping already applied)

### ❓ Open Questions

1. **Is the delivery status grouping intentional in tracking?**
   - Should `shopPosition` be the global position instead of position-within-status-group?
   - Can this be fixed at the tracking source?

2. **Why do ~10% of pagination events have different `searchTrackingId`?**
   - Is this a tracking bug?
   - Or does the app sometimes regenerate the search request when paginating?

3. **How should we handle pagination edge cases?**
   - Should we group by `(session_key, search_term)` instead?
   - Or is there a better identifier to link pagination events to their original search?

4. **Are there other position-related edge cases we're missing?**
   - Filters applied mid-search?
   - Sorting changes?
   - Map/list view toggles?

---

## Validation & Testing

### Manual Validation Performed
- Searched several test queries (e.g., "pizza", "chicken", "coffee")
- Compared `shopsIds` order with actual app display
- Verified positions match across `shop_list.updated` and visual results

### Metrics Calculated Using This Approach
- **Average Click Position** (`avg_click_rank`): AVG(correct_position)
- **First Click Position** (`first_click_rank`): MIN(correct_position)
- **Clicks by Position Buckets**:
  - Position 1: `COUNTIF(first_click_rank = 1)`
  - Position 2-3: `COUNTIF(first_click_rank BETWEEN 2 AND 3)`
  - Position 4-10: `COUNTIF(first_click_rank BETWEEN 4 AND 10)`
  - Position 11+: `COUNTIF(first_click_rank > 10)`

### Known Limitations
1. **~10% of pagination may be miscounted** due to `searchTrackingId` mismatch
2. **Assumes `shopsIds` order is canonical** and matches user's visual display
3. **Cannot validate if status grouping changed mid-session** (e.g., vendor went from "Delivering" to "Preparing" while user was viewing)

---

## Recommendations for Tracking Team

### High Priority Fixes
1. **Fix `shopPosition` to be global position**: Stop resetting positions by delivery status. Position should be 0, 1, 2, ... N across the entire result set, regardless of status grouping.

2. **Investigate `searchTrackingId` inconsistency**: Why do 10% of pagination events have different tracking IDs? Can we make pagination events consistently use the same ID as the original search?

### Low Priority Improvements
3. **Add `globalPosition` field**: Explicitly track both:
   - `positionInStatusGroup` (current behavior)
   - `globalPosition` (position across entire result set)

4. **Add pagination sequence number**: Add explicit `paginationSequence` field (0, 1, 2, ...) to make it easier to identify which page a user is viewing

---

## Impact on Analysis

### What This Hack Enables
✅ Accurate calculation of average click position  
✅ Ranking quality metrics (% clicks in top 3, top 10, etc.)  
✅ Fair comparison between Woowa Search and Global Search click behavior  
✅ Identification of queries where users click too far down (poor ranking)  

### What We Still Can't Measure
❌ Click position by delivery status (data lost in our workaround)  
❌ 100% accurate pagination behavior (~10% may be miscounted)  
❌ Changes in vendor ordering mid-session (if status changed while viewing)  

---

## Changelog

| Date | Change | Reason |
|------|--------|--------|
| 2026-05-XX | Initial implementation of position correction | Discovered position resets by delivery status |
| 2026-06-12 | Documented in this file | Ensure knowledge is preserved for future analysis |

---

## Contact

For questions about this implementation or to discuss tracking improvements:
- **Analysis Team**: Add contact info
- **Tracking Team**: Add contact info
- **Related Documents**: 
  - `comprehensive_comparison_query.sql` (lines 32-65)
  - `DATA_FILTERING_CONSTRAINTS.md`
