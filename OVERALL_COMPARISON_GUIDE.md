# Overall AB Test Query Guide

## 🎯 What This Query Does

This query provides a **high-level, aggregated view** of AB test performance across **ALL search queries combined**, comparing Control (A) vs Treatment (B).

Unlike the detailed query that shows performance for each individual search term, this query gives you:
- ✅ **Overall CTR/CVR** comparison between Control and Treatment
- ✅ **Total search volume** per variation
- ✅ **Aggregate click rank** distribution
- ✅ **Traffic split validation** (~50/50)
- ✅ **Session-level engagement**
- ✅ **Statistical significance** testing

**Use this for:** Executive summaries, AB test check-ins, high-level performance monitoring

**Use the detailed query for:** Deep-dive analysis, identifying winning/losing queries

---

## 📊 Expected Output

You'll get **2-3 rows** (one per vertical):

| search_vertical | control_searches | control_cvr | treatment_searches | treatment_cvr | cvr_pct_change | cvr_stat_sig | treatment_traffic_pct |
|-----------------|------------------|-------------|--------------------|--------------:|---------------:|--------------|----------------------:|
| ALL | 1,250,000 | 0.0450 | 1,280,000 | 0.0485 | **+7.78%** | ✅ Yes | 50.6% |
| BAEMIN_DELIVERY | 980,000 | 0.0420 | 1,000,000 | 0.0455 | **+8.33%** | ✅ Yes | 50.5% |

---

## 🔑 Key Differences from Detailed Query

| Aspect | Detailed Query | Overall Query |
|--------|---------------|---------------|
| **Granularity** | Per search term | All searches aggregated |
| **Rows** | Hundreds/thousands | 2-3 (one per vertical) |
| **Volume filter** | Treatment ≥5 searches per term | No filter (shows all) |
| **Use case** | Find winning/losing queries | Executive summary |
| **Best for** | Deep analysis | AB test check-ins |

---

## 📈 Metrics Included

### Volume Metrics
- **`control_searches`** / **`treatment_searches`**: Total number of searches per variation
- **`control_sessions`** / **`treatment_sessions`**: Unique user sessions
- **`treatment_traffic_pct`**: % of traffic in Treatment (should be ~50%)

### Funnel Metrics
- **`control_ctr`** / **`treatment_ctr`**: Click-Through Rate
- **`control_cvr`** / **`treatment_cvr`**: Conversion Rate (searches → orders)
- **`control_click_to_order_rate`** / **`treatment_click_to_order_rate`**: % of clicks that convert

### Quality Metrics
- **`control_zrr`** / **`treatment_zrr`**: Zero Result Rate (% of searches with no results)
- **`control_avg_click_rank`** / **`treatment_avg_click_rank`**: Average position of first click
- **`control_avg_results`** / **`treatment_avg_results`**: Average number of results returned

### Engagement Metrics
- **`control_pagination_rate`** / **`treatment_pagination_rate`**: % of searches that paginate
- **`control_searches_per_session`** / **`treatment_searches_per_session`**: Avg searches per session

### Comparison Metrics
- **`ctr_pct_change`** / **`cvr_pct_change`**: % difference Treatment vs Control
- **`ctr_statistically_significant`** / **`cvr_statistically_significant`**: Statistical significance (z-test)

---

## 🎯 How to Interpret Results

### 1. Check Traffic Split First ✅

**Look at:** `treatment_traffic_pct`

**Good:**
- 48-52% → Traffic split is balanced ✅
- AB test randomization is working correctly

**Red Flag:**
- <45% or >55% → Imbalanced traffic ⚠️
- Check assignment logic or filtering issues

---

### 2. Evaluate CVR Performance 📈

**Look at:** `cvr_pct_change` and `cvr_statistically_significant`

**Winning Treatment:**
```
control_cvr:  0.0450
treatment_cvr: 0.0485
cvr_pct_change: +7.78%
cvr_stat_sig: Yes ✅
```
- **Interpretation:** Treatment is winning, statistically significant improvement

**Losing Treatment:**
```
control_cvr:  0.0450
treatment_cvr: 0.0438
cvr_pct_change: -2.67%
cvr_stat_sig: Yes ⚠️
```
- **Interpretation:** Treatment is losing, statistically significant degradation

**Inconclusive:**
```
control_cvr:  0.0450
treatment_cvr: 0.0455
cvr_pct_change: +1.11%
cvr_stat_sig: No
```
- **Interpretation:** Slight improvement but not statistically significant, need more data

---

### 3. Understand CTR Changes 👆

**Look at:** `ctr_pct_change` and `ctr_statistically_significant`

**Good Patterns:**
- ✅ CTR ↑, CVR ↑ → Better ranking + more relevant results
- ✅ CTR ↔, CVR ↑ → Same clicks, better conversion (higher quality clicks)

**Concerning Patterns:**
- ⚠️ CTR ↑, CVR ↓ → More clicks but worse conversion (clickbait ranking?)
- ⚠️ CTR ↓, CVR ↑ → Fewer clicks but better conversion (investigate why CTR dropped)

---

### 4. Check Click Position 🎯

**Look at:** `control_avg_click_rank` vs `treatment_avg_click_rank`

**Good:**
- Treatment avg click rank < Control avg click rank
- Users clicking on higher-ranked (more prominent) results

**Example:**
```
control_avg_click_rank:  3.5
treatment_avg_click_rank: 2.8
```
- **Interpretation:** Treatment users click 0.7 positions higher → Better ranking relevance

---

## 🚨 Common Patterns

### Pattern 1: Clear Win ✅
```
CVR: +10%, statistically significant
CTR: +5%, statistically significant
Avg Click Rank: -0.5 (improved)
Traffic Split: 50.2%
```
**Action:** Ship Treatment

---

### Pattern 2: Neutral Result 🤷
```
CVR: +1%, not significant
CTR: +0.5%, not significant
Avg Click Rank: +0.1
Traffic Split: 50.0%
```
**Action:** Need more data or not worth shipping

---

### Pattern 3: Mixed Results ⚠️
```
CVR: +8%, statistically significant
CTR: -3%, statistically significant
Avg Click Rank: -1.0 (improved)
Traffic Split: 50.5%
```
**Action:** Investigate further - better conversion but fewer clicks. Check:
- Zero Result Rate (fewer results returned?)
- Drill down by tier (Head/Torso/Tail)
- Check specific queries (detailed query)

---

### Pattern 4: Traffic Split Issue 🚫
```
CVR: +15%, statistically significant
CTR: +12%, statistically significant
Traffic Split: 65%  ← PROBLEM!
```
**Action:** Don't trust results - imbalanced traffic indicates filtering/assignment bug

---

## 💡 Next Steps After Overall Query

### If Treatment is Winning:
1. ✅ Run **Head/Torso/Tail query** → Which tier drives the win?
2. ✅ Run **Detailed query** → Which specific queries win?
3. ✅ Run **Query Classification** → Which query types win?
4. ✅ Run **Exact Match Analysis** → Does exact match positioning improve?
5. ✅ Validate consistency across all dimensions before shipping

### If Treatment is Losing:
1. ⚠️ Run **Head/Torso/Tail query** → Which tier is losing?
2. ⚠️ Run **Detailed query** → Which specific queries lose?
3. ⚠️ Investigate root cause (ranking, relevance, performance?)

### If Results are Mixed/Unclear:
1. 🤔 Check **sample size** - enough data for significance?
2. 🤔 Run **tier breakdown** - is one tier offsetting another?
3. 🤔 Check **traffic split** - is randomization working?

---

## 📊 Example Analysis Workflow

**Step 1: Overall Check**
```sql
-- Run overall_comparison_query_ab_test.sql
-- Result: Treatment +7.78% CVR, statistically significant, 50.6% traffic ✅
```

**Step 2: Drill Down**
```sql
-- Run head_torso_tail_comparison_query_ab_test.sql
-- Result: Head +12% CVR, Torso +5% CVR, Tail +2% CVR (not sig)
```

**Step 3: Investigate**
```sql
-- Run comprehensive_comparison_query_ab_test.sql
-- Result: Top 10 queries all winning, bottom 20% flat
```

**Step 4: Validate**
```sql
-- Run query_classification_breakdown_ab_test.sql
-- Result: Restaurant queries +15% CVR, Item queries +3% CVR
```

**Conclusion:** Treatment is a clear win, driven by Head tier and restaurant queries. Ship it! ✅

---

## 🎯 Key Takeaways

1. **Always check traffic split first** - Invalid if not ~50/50
2. **CVR is the primary metric** - Orders matter most
3. **Statistical significance matters** - Don't ship on noise
4. **Drill down on mixed results** - Overall can hide important details
5. **Use this as your starting point** - Then drill down with other queries

---

## 📅 Date Range

All queries use **fixed date range: May 30 - June 17, 2026 (inclusive)**

This ensures:
- ✅ Consistent analysis window
- ✅ Reproducible results
- ✅ Easy comparison across queries

---

## 🔗 Related Queries

- **`head_torso_tail_comparison_query_ab_test.sql`** - Drill down by tier
- **`comprehensive_comparison_query_ab_test.sql`** - Drill down by query
- **`query_classification_breakdown_ab_test.sql`** - Drill down by classification
- **`exact_match_analysis_queries.sql`** - Restaurant query analysis
