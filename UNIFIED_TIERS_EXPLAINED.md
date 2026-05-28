# Unified Tiers Explained - Option A Implementation

## What Changed (May 27, 2026)

### The Problem with Separate Tiers

**Before:** Tiers were calculated separately for each system:
- Woowa Search: Top 50% of Woowa volume = Head
- Global Search: Top 50% of Global volume = Head

**Issue:** Same query could be in different tiers!

Example:
| Query | Woowa Searches | Woowa Tier | Global Searches | Global Tier |
|-------|----------------|------------|-----------------|-------------|
| pizza | 2,000 | Head | 300 | Torso |
| sushi | 800 | Torso | 150 | Tail |

😕 **Confusing** - You're comparing different query sets per tier!

---

### The Solution: Unified Tiers (Option A)

**Now:** Tiers are calculated based on **COMBINED traffic** from both systems:

1. **Combine** all searches: Woowa + Global Search
2. **Rank** queries by total volume
3. **Assign** tiers:
   - Top 50% of **combined** volume = **Head**
   - Next 30% of **combined** volume = **Torso**
   - Bottom 20% of **combined** volume = **Tail**
4. **Apply** same tier to both systems

Example:
| Query | Combined Searches | Tier | Woowa Searches | Global Searches |
|-------|-------------------|------|----------------|-----------------|
| pizza | 2,300 | Head | 2,000 | 300 |
| sushi | 950 | Head | 800 | 150 |

✅ **Clear** - Same tier for both systems!

---

## How It Works

### Step 1: Calculate Combined Volume

```sql
combined_search_volume AS (
  SELECT
    search_term,
    search_vertical,
    COUNT(*) AS total_searches_combined,  -- Woowa + Global
    SUM(COUNT(*)) OVER (
      PARTITION BY search_vertical  -- Only by vertical, NOT by system
      ORDER BY COUNT(*) DESC
    ) AS cumulative_searches
  FROM search_grain  -- Contains both systems
  GROUP BY search_vertical, search_term
)
```

**Key:** No partition by `account_id_group` - we want total across both!

---

### Step 2: Assign Tiers by Cumulative Percentage

```sql
unified_tier_assignment AS (
  SELECT
    search_term,
    search_vertical,
    CASE
      WHEN cumulative_searches / total <= 0.50 THEN 'Head'
      WHEN cumulative_searches / total <= 0.80 THEN 'Torso'
      ELSE 'Tail'
    END AS frequency_tier
  FROM combined_search_volume
)
```

**Result:** Each query gets ONE tier based on combined traffic.

---

### Step 3: Apply to Both Systems

```sql
search_grain_with_tier AS (
  SELECT
    sg.*,
    uta.frequency_tier  -- Same tier for both Woowa and Global
  FROM search_grain sg
  LEFT JOIN unified_tier_assignment uta
    ON sg.search_vertical = uta.search_vertical
    AND sg.search_term = uta.search_term
)
```

---

## Benefits of Unified Tiers

### 1. ✅ Apples-to-Apples Comparison

**Before (Separate Tiers):**
```
Head tier in Woowa: "pizza", "chicken", "sushi"
Head tier in Global: "burger", "ramen", "korean bbq"
```
Comparing different queries!

**After (Unified Tiers):**
```
Head tier (both systems): "pizza", "chicken", "sushi"
```
Same queries, fair comparison!

---

### 2. ✅ More Meaningful Insights

**Example Output:**
```
Head tier (top 50% combined volume):
- Woowa Search CTR: 12.5%
- Global Search CTR: 14.2% (+13.6%)
✅ Global Search is better on the most important queries!
```

You know Global Search is improving **on the same high-value queries**.

---

### 3. ✅ Better Prioritization

**With unified tiers:**
- "pizza" is Head tier → Optimize it in both systems
- Even if Global Search has low pizza volume now, you know it's important overall

**Without unified tiers:**
- "pizza" might be Tail in Global → Deprioritized
- Miss opportunity to optimize important query

---

### 4. ✅ Easier to Understand

**Question:** "How is Global Search performing on Head queries?"

**Unified Tiers Answer:**
"Global Search CTR on Head queries: +13.6% vs Woowa"
✅ Clear, actionable

**Separate Tiers Answer:**
"Wait, which Head queries? Woowa's Head or Global's Head?"
😕 Confusing

---

## Example Scenario

### Combined Volume (ALL vertical):

| Query | Woowa | Global | Combined | Cumulative % | Tier |
|-------|-------|--------|----------|--------------|------|
| pizza | 2,000 | 300 | **2,300** | 15% | Head |
| chicken | 1,800 | 250 | **2,050** | 28% | Head |
| sushi | 1,200 | 180 | **1,380** | 37% | Head |
| burger | 900 | 120 | **1,020** | 44% | Head |
| ramen | 800 | 100 | **900** | 50% | Head ← cutoff |
| korean bbq | 600 | 80 | **680** | 54% | Torso |
| ... | ... | ... | ... | ... | ... |

**Result:**
- Head: Top 5 queries (50% of volume)
- Torso: Next 30% of volume
- Tail: Remaining 20% of volume

---

## Query Output Interpretation

### Row Example:

| search_vertical | frequency_tier | tier_definition | woowa_searches | global_searches | woowa_ctr | global_ctr | ctr_pct_change |
|-----------------|----------------|-----------------|----------------|-----------------|-----------|------------|----------------|
| ALL | Head | Top 50% of combined volume | 85,340 | 12,450 | 0.1250 | 0.1420 | +13.6% |

**What this means:**
- **Head tier**: Includes all queries that make up the top 50% of **total** volume (Woowa + Global combined)
- **Woowa searches**: 85,340 searches in Woowa Search for these Head queries
- **Global searches**: 12,450 searches in Global Search for **the same** Head queries
- **CTR comparison**: Global Search has +13.6% higher CTR on these same Head queries

---

## Edge Cases

### What if Global Search doesn't have data for a query?

**Scenario:**
- "late night delivery" is in Head tier (high Woowa volume)
- But Global Search has 0 searches for it (not assigned yet)

**Result:**
```
Head tier:
- Woowa: 85,340 searches, CTR: 12.5%
- Global: 12,450 searches, CTR: 14.2%
```

Global Search metrics only include queries where it **has data**.

**This is fine!** You're still comparing performance on the **overlap**.

---

### What if Tail has more Global searches than Head?

**Scenario (early in test):**
- Global Search traffic is sparse
- Happens to get random Tail queries

**Result:**
```
Tail tier:
- Woowa: 11,550 searches
- Global: 8,900 searches  ← More than expected
```

**This is temporary!** As Global Search scales, distribution will normalize.

---

## Comparison: Separate vs Unified

### Metric: "How does Global Search perform on high-value queries?"

**Separate Tiers (Old):**
```
Global Search Head tier (its own top 50%):
- Searches: 8,234
- CTR: 11.2%
```
❌ Doesn't tell you if these are the **important** queries overall

**Unified Tiers (New):**
```
Head tier (top 50% overall):
- Woowa: 85,340 searches, CTR: 12.5%
- Global: 12,450 searches, CTR: 14.2%
```
✅ Tells you Global is **+13.6% better on the same important queries**

---

## Date Change (Also Updated)

### Timezone Issue

**Problem:** Woowa is in Korea (UTC+9), ahead of most timezones

**Solution:** Changed all queries to use **CURRENT_DATE()** instead of **CURRENT_DATE() - 1**

**Rationale:**
- 9am your time → Most of Woowa's day is done
- 5pm your time → Woowa's full day is complete
- Running "today's" query gives you near-complete data

**Files Updated:**
- ✅ `overall_comparison_query.sql`
- ✅ `comprehensive_comparison_query.sql`
- ✅ `head_torso_tail_comparison_query.sql`
- ✅ `daily_alert_report_query.sql`

---

## Summary

**Before:**
- Separate tiers per system
- Different queries in each tier
- Confusing comparisons
- Query runs for "yesterday"

**After:**
- ✅ Unified tiers based on combined traffic
- ✅ Same queries in same tiers
- ✅ Clear apples-to-apples comparison
- ✅ Query runs for "today" (matches Woowa timezone)

**Bottom Line:**
When you see "Head tier +13% CTR", you now know **exactly what that means**: Global Search performs 13% better on the **same high-value queries** that make up the top 50% of total search traffic.

---

Last Updated: May 27, 2026
