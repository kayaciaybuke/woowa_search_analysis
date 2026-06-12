# Query Classification Breakdown Guide

## Overview
This query analyzes AB test performance across **3 dimensions**:
1. **Vertical** (ALL vs BAEMIN_DELIVERY)
2. **Tier** (Head / Torso / Tail)
3. **Query Classification** (restaurant / item / cuisine / unclassified)

**Time Range:** Last 2 weeks  
**Data Lag:** D+1 (yesterday's data is the most recent)

---

## Query Classifications

Classifications come from the backend tracking table's query expansion service:
- **`restaurant`**: Brand/vendor name queries (e.g., "스타벅스", "BHC", "빽다방")
- **`item`**: Menu item queries (e.g., "오리탕", "치킨")
- **`cuisine`**: Food category queries (e.g., "도넛", "김밥")
- **`unclassified`**: Queries without classification in backend tracking

**Important:** Only Treatment (B) has query classifications in backend tracking. The query joins classifications by `search_term`, so both Control and Treatment get the same classification for the same query.

---

## Output Structure

### Columns

**Dimensions:**
- `search_vertical`: ALL or BAEMIN_DELIVERY
- `tier`: Head, Torso, or Tail (based on combined A+B volume)
- `classification`: restaurant, item, cuisine, or unclassified

**Control (A) Metrics:**
- `control_searches`: Number of searches
- `control_ctr`: Click-through rate
- `control_cvr`: Conversion rate
- `control_avg_click_rank`: Average position clicked
- `control_clicks_pos_1`: Clicks on position 1

**Treatment (B) Metrics:**
- `treatment_searches`: Number of searches
- `treatment_ctr`: Click-through rate
- `treatment_cvr`: Conversion rate
- `treatment_avg_click_rank`: Average position clicked
- `treatment_clicks_pos_1`: Clicks on position 1

**Deltas:**
- `ctr_pct_change`: % change in CTR (Treatment vs Control)
- `cvr_pct_change`: % change in CVR (Treatment vs Control)
- `avg_click_rank_diff`: Difference in avg click rank (Treatment - Control)
- `ctr_significant`: Statistical significance (Yes/No/Insufficient Data)

---

## Sample Output

```
| vertical         | tier  | classification | control_searches | control_ctr | treatment_searches | treatment_ctr | ctr_pct_change | ctr_significant |
|------------------|-------|----------------|------------------|-------------|--------------------|---------------|----------------|-----------------|
| ALL              | Head  | restaurant     | 150,000          | 0.0985      | 148,500            | 0.1123        | +14.01%        | Yes             |
| ALL              | Head  | cuisine        | 45,000           | 0.0812      | 44,200             | 0.0945        | +16.38%        | Yes             |
| ALL              | Head  | item           | 38,000           | 0.0756      | 37,500             | 0.0889        | +17.59%        | Yes             |
| ALL              | Head  | unclassified   | 12,000           | 0.0623      | 11,800             | 0.0701        | +12.52%        | Yes             |
| ALL              | Torso | restaurant     | 85,000           | 0.0721      | 83,500             | 0.0834        | +15.67%        | Yes             |
| ...              | ...   | ...            | ...              | ...         | ...                | ...           | ...            | ...             |
```

---

## Key Insights to Look For

### 1. Which Query Types Perform Best Overall?
```sql
-- Sort by classification to see overall performance
ORDER BY classification, tier, search_vertical
```
- Are `restaurant` queries (brand searches) performing better than `cuisine` queries?
- Do `item` queries have lower CTR because users are browsing more?

### 2. Where is Treatment Winning/Losing?
```sql
-- Focus on rows with significant differences
WHERE ctr_significant = 'Yes'
  AND ABS(ctr_pct_change) > 10
```
- Which classification × tier combinations show the biggest CTR improvements?
- Are there any segments where Treatment is performing worse?

### 3. Tier-Specific Patterns by Classification
```sql
-- Compare Head vs Torso vs Tail for each classification
WHERE classification = 'restaurant'
ORDER BY tier
```
- Does Treatment's improvement in Head tier carry through to Torso and Tail?
- Are Tail queries (long-tail) benefiting more or less from Treatment?

### 4. Vertical Differences by Classification
```sql
-- Compare ALL vs BAEMIN_DELIVERY
WHERE tier = 'Head' AND classification = 'restaurant'
ORDER BY search_vertical
```
- Are improvements consistent across ALL and BAEMIN_DELIVERY tabs?
- Does one vertical perform significantly better for certain query types?

---

## Common Questions

### Q: Why do some classifications have very few searches?
**A:** The tier calculation is done **per vertical**, so:
- Head tier = top 50% of volume **within that vertical**
- Torso tier = next 30% of volume **within that vertical**
- Tail tier = bottom 20% of volume **within that vertical**

Within each tier, classifications are further broken down, so some combinations (e.g., `item` queries in `Tail` tier) may have low volume.

### Q: What does "unclassified" mean?
**A:** Queries that don't have a classification in the backend tracking table. This could be:
- New/rare queries that haven't been classified yet
- Non-Korean queries
- Queries that failed classification for some reason

### Q: Why is Treatment avg_click_rank sometimes higher (worse)?
**A:** Higher avg_click_rank can mean:
1. **More results shown**: Treatment might be surfacing more vendors, so users explore deeper
2. **Better top results**: If top positions are highly relevant, users may still click but also explore alternatives
3. **Different ranking**: Treatment's ranking algorithm prioritizes different factors

**Check CTR and CVR** to see if the overall experience improved despite higher click positions.

### Q: Should I trust results with "Insufficient Data"?
**A:** No. When `ctr_significant = 'Insufficient Data'`:
- Either Control or Treatment has <30 searches in that segment
- Statistical tests are unreliable with low sample sizes
- Focus on segments with sufficient data for decision-making

---

## Filtering Tips

### Focus on High-Volume Segments
```sql
WHERE control_searches >= 1000 AND treatment_searches >= 1000
```

### Exclude Unclassified (if analyzing known types)
```sql
WHERE classification != 'unclassified'
```

### Focus on Statistically Significant Results
```sql
WHERE ctr_significant = 'Yes'
```

### Analyze Specific Vertical
```sql
WHERE search_vertical = 'BAEMIN_DELIVERY'
```

### Analyze Specific Tier
```sql
WHERE tier = 'Head'
```

---

## Relationship to Other Queries

**How this differs from `overall_comparison_query_ab_test.sql`:**
- Overall query: Aggregates across all queries (no classification dimension)
- This query: Breaks down by query classification type

**How this differs from `head_torso_tail_comparison_query_ab_test.sql`:**
- Head/Torso/Tail query: Shows performance by tier only
- This query: Adds classification dimension to tier analysis

**How this differs from `comprehensive_comparison_query_ab_test.sql`:**
- Comprehensive query: Shows individual query performance (very granular)
- This query: Aggregates queries by classification type (mid-level granularity)

---

## Use Cases

### 1. Strategic Prioritization
**Question:** "Should we prioritize improving restaurant searches or cuisine searches?"

**How to answer:**
1. Filter to `Head` tier (highest volume impact)
2. Compare `ctr_pct_change` across classifications
3. Focus optimization efforts on classification with most room for improvement

### 2. AB Test Evaluation
**Question:** "Is the new ranking algorithm working well across all query types?"

**How to answer:**
1. Check if `ctr_pct_change` is positive across all classifications
2. Look for any classifications where Treatment performs worse
3. Investigate those segments to understand why

### 3. Product Decisions
**Question:** "Should we build specialized features for item searches vs restaurant searches?"

**How to answer:**
1. Compare CTR/CVR patterns between `item` and `restaurant` classifications
2. If `item` queries have much lower CTR, they may benefit from specialized UI (e.g., filters, images)
3. If `restaurant` queries perform well, prioritize features for that flow

### 4. Long-Tail Analysis
**Question:** "Are Tail queries benefiting from the new algorithm?"

**How to answer:**
1. Filter to `tier = 'Tail'`
2. Check if `ctr_pct_change` is positive and significant
3. Compare improvement magnitude between Head and Tail tiers

---

## Troubleshooting

### Issue: All queries show "unclassified"
**Possible causes:**
- Backend tracking table doesn't have data for your date range
- Query classifications table is empty
- Join condition on `search_term` is failing (check for case sensitivity, whitespace)

**Solution:**
```sql
-- Debug: Check if classifications exist
SELECT classification, COUNT(*) 
FROM query_classifications 
GROUP BY classification;
```

### Issue: Treatment has many more searches than Control
**Expected behavior:** This is normal if:
- More users are assigned to Treatment (check assignment table)
- Treatment users are more engaged (higher search rate)

**Not expected:** Check if there's an issue with the assignment join logic.

### Issue: Some vertical × tier × classification combinations are missing
**Expected behavior:** Not all combinations exist in data. For example:
- `ALL` vertical might not have many `item` queries in `Head` tier
- `BAEMIN_DELIVERY` might have different classification distribution

**Solution:** Use `FULL OUTER JOIN` in the final pivot (query already does this).

---

## Related Files
- `overall_comparison_query_ab_test.sql` - Overall AB test metrics
- `head_torso_tail_comparison_query_ab_test.sql` - Tier-level AB test metrics
- `comprehensive_comparison_query_ab_test.sql` - Query-level AB test metrics
- `AB_TEST_QUICK_START.md` - AB test setup and requirements
