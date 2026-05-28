# Query Comparison: Overall vs Detailed

## 📊 Side-by-Side Comparison

| Feature | Overall Query | Detailed Query |
|---------|--------------|----------------|
| **Granularity** | All searches aggregated | Per search term |
| **Output Rows** | 3 (one per vertical) | Hundreds/thousands |
| **Volume Filter** | None (all searches included) | Global Search ≥5 searches per term |
| **Best For** | Executive summaries, trends | Finding specific issues |
| **Update Frequency** | Daily/Weekly | When issues found |
| **Export Size** | Small (3 rows) | Large (filter recommended) |
| **Statistical Significance** | Always has enough volume | May have "Insufficient Data" |
| **Search Terms Shown** | Not shown (aggregated) | Individual terms visible |

---

## 🎯 When to Use Each

### Overall Query → "How Are We Doing?"

**Use Cases:**
- ✅ Monday morning health check
- ✅ Weekly status report for stakeholders
- ✅ Tracking CTR/CVR trends over time
- ✅ Quick comparison: "Is AWS better overall?"
- ✅ Executive dashboard metrics

**Sample Question:**
> "What's our overall CTR this week compared to last week?"

**Answer from Overall Query:**
```
Overall CTR: 10.5% → 12.1% (+15.2%) ✅
```

---

### Detailed Query → "What Should We Fix?"

**Use Cases:**
- ✅ Finding underperforming search terms
- ✅ Prioritizing optimization work
- ✅ Deep-dive after overall metrics drop
- ✅ Understanding which searches drive metrics
- ✅ Analyzing specific search behavior

**Sample Question:**
> "Overall CTR dropped 5% - which searches are causing this?"

**Answer from Detailed Query:**
```
Top 5 CTR Droppers:
1. "pizza" (10K searches): -15% CTR
2. "sushi" (8K searches): -12% CTR
3. "burger" (7K searches): -10% CTR
...
```

---

## 📋 Example Workflow

### Scenario: Weekly Performance Review

**Step 1: Run Overall Query (Last 7 Days)**
```
Result:
- Overall CTR: 10.2%
- Overall CVR: 4.1%
- All statistically significant vs woowa search ✅
```

**Conclusion:** Overall health is good → No action needed

---

**Step 2: If Overall Shows Issues**
```
Result:
- Overall CTR: 8.5% (down from 10.2% last week) ⚠️
- Overall CVR: 3.2% (down from 4.1%)
```

**Action:** Run Detailed Query to find culprits

---

**Step 3: Run Detailed Query**
```
Filter by: search_popularity = 'High Frequency'
Sort by: ctr_pct_change ASC (worst first)

Top 3 Underperformers:
1. "birthday cake" (5K searches): CTR -25%
2. "chicken" (4K searches): CTR -18%
3. "pizza delivery" (3.5K searches): CTR -15%
```

**Action:** Investigate these 3 searches (12.5K total searches = 65% of traffic)

---

## 📊 Output Comparison

### Overall Query Output:
```
3 rows total

search_vertical | woowa_search_searches | woowa_search_ctr | global_search_searches | global_search_ctr | ctr_pct_change
----------------|-------------|--------|--------------|---------|---------------
ALL             | 125,340     | 0.0985 | 89,250       | 0.1123  | +14.01%
BAEMIN_DELIVERY | 198,450     | 0.0912 | 142,680      | 0.1045  | +14.58%
NULL_VERTICAL   | 45,820      | 0.6234 | 12,450       | 0.5987  | -3.96%
```

**Quick Insights:**
- ALL & DELIVERY: Global Search performing better ✅
- NULL_VERTICAL: Slight drop (monitor) ⚠️

---

### Detailed Query Output:
```
1,247 rows total (example - first 5)

search_vertical | search_query    | search_popularity | woowa_search_searches | woowa_search_ctr | global_search_searches | global_search_ctr | ctr_pct_change
----------------|-----------------|-------------------|-------------|--------|--------------|---------|---------------
ALL             | birthday cake   | High Frequency    | 4,520       | 0.1200 | 3,890        | 0.1478  | +23.17%
BAEMIN_DELIVERY | pizza           | High Frequency    | 3,680       | 0.0950 | 2,740        | 0.1100  | +15.79%
ALL             | chicken rice    | High Frequency    | 2,340       | 0.0850 | 1,920        | 0.0720  | -15.29%
BAEMIN_DELIVERY | sushi           | Medium Frequency  | 850         | 0.0800 | 650          | 0.0947  | +18.38%
NULL_VERTICAL   | fried chicken   | High Frequency    | 1,200       | 0.7100 | 280          | 0.6800  | -4.23%
```

**Actionable Insights:**
- "chicken rice": -15% CTR on 2,340 searches → Investigate! 🔍
- "birthday cake": +23% CTR → What's working well? ✅
- "pizza": +16% CTR on 3,680 searches → Strong win ✅

---

## 💡 Pro Tips

### 1. Start Broad, Then Narrow
```
Monday: Run Overall → Everything looks good ✅
(No need to run Detailed)

Tuesday: Run Overall → CVR dropped 8% ⚠️
→ Now run Detailed to find why
```

### 2. Export Strategy
- **Overall**: Export every week → Track trends in sheets
- **Detailed**: Export on-demand → When investigating issues

### 3. Filter Detailed Results
The detailed query returns thousands of rows. Filter by:
```sql
-- In BigQuery after running:
WHERE search_popularity = 'High Frequency'  -- Focus on impact
  AND global_search_searches >= 100                   -- Meaningful volume
  AND ctr_statistically_significant = 'Yes' -- Real differences
ORDER BY ctr_pct_change ASC                 -- Worst first
```

### 4. Combine Both for Reports
**Weekly Report Structure:**
1. **Summary** (Overall Query):
   - Overall CTR/CVR: Up/Down/Flat
   - Statistical significance: Yes/No
   
2. **Top Wins** (Detailed Query):
   - Top 5 searches with highest CTR improvement
   
3. **Action Items** (Detailed Query):
   - Top 5 searches needing attention

---

## 🎓 Learning Path

### Week 1: Get Familiar
- Run **Overall Query** daily
- Observe patterns
- Understand normal ranges

### Week 2: Deep Dive
- Run **Detailed Query** once
- Explore high-frequency searches
- Identify top performers

### Week 3: Monitor & Act
- **Overall** for daily health checks
- **Detailed** when metrics change
- Take action on findings

---

## 📁 File Locations

- Overall Query: `~/woowa_search_analysis/overall_comparison_query.sql`
- Detailed Query: `~/woowa_search_analysis/comprehensive_comparison_query.sql`
- Overall Guide: `~/woowa_search_analysis/OVERALL_COMPARISON_GUIDE.md`
- This Comparison: `~/woowa_search_analysis/QUERY_COMPARISON.md`

---

## 🆘 Quick Decision Tree

```
Need high-level summary?
├─ YES → Use Overall Query
└─ NO → Need to find specific problems?
         ├─ YES → Use Detailed Query
         └─ NO → Start with Overall, then go Detailed if needed
```

---

## 📅 Last Updated
May 27, 2026
