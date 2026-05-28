# Overall Comparison Query Guide

## 🎯 What This Query Does

This query provides a **high-level, aggregated view** of search performance across **ALL search queries combined**.

Unlike the detailed query that shows performance for each individual search term, this query gives you:
- ✅ **Overall CTR/CVR** across all searches
- ✅ **Total search volume** comparison
- ✅ **Aggregate click rank** distribution
- ✅ **Overall pagination behavior**
- ✅ **Session-level engagement**

**Use this for:** Executive summaries, weekly reports, high-level trend monitoring

**Use the detailed query for:** Deep-dive analysis, problematic search term identification

---

## 📊 Expected Output

You'll get **3 rows** (one per vertical):

| search_vertical | woowa_search_total_searches | woowa_search_ctr | woowa_search_cvr | global_search_total_searches | global_search_ctr | global_search_cvr | ctr_pct_change | ctr_significant |
|-----------------|-------------------|--------|--------|-------------------|---------|---------|----------------|----------------|
| ALL | 125,340 | 0.0985 | 0.0412 | 89,250 | 0.1123 | 0.0465 | **+14.01%** | Yes |
| BAEMIN_DELIVERY | 198,450 | 0.0912 | 0.0389 | 142,680 | 0.1045 | 0.0438 | **+14.58%** | Yes |
| NULL_VERTICAL | 45,820 | 0.6234 | 0.7496 | 12,450 | 0.5987 | 0.7201 | **-3.96%** | No |

---

## 🔑 Key Differences from Detailed Query

| Aspect | Detailed Query | Overall Query |
|--------|---------------|---------------|
| **Granularity** | Per search term | All searches aggregated |
| **Rows** | Hundreds/thousands | 3 (one per vertical) |
| **Volume filter** | Global Search ≥5 searches per term | No filter (shows all) |
| **Use case** | Find problematic searches | Executive summary |
| **Best for** | Deep analysis | Trend monitoring |

---

## 📈 Metrics Included

### Volume Metrics
- **`woowa_search_total_searches`** / **`global_search_total_searches`**: Total number of searches
- **`woowa_search_unique_sessions`** / **`global_search_unique_sessions`**: Unique user sessions
- **`woowa_search_unique_search_terms`** / **`global_search_unique_search_terms`**: How many different queries

### Core Funnel
- **`woowa_search_ctr`** / **`global_search_ctr`**: Overall Click-Through Rate
- **`woowa_search_cvr`** / **`global_search_cvr`**: Overall Conversion Rate
- **`woowa_search_zrr`** / **`global_search_zrr`**: Overall Zero Result Rate

### Quality Metrics
- **`woowa_search_avg_results`** / **`global_search_avg_results`**: Average vendors shown
- **`woowa_search_avg_click_rank`** / **`global_search_avg_click_rank`**: Average position clicked

### Click Distribution (NEW!)
- **`woowa_search_pct_clicks_pos_1`** / **`global_search_pct_clicks_pos_1`**: % of clicks on position 1
- **`woowa_search_pct_clicks_pos_2_3`** / **`global_search_pct_clicks_pos_2_3`**: % of clicks on positions 2-3

### Filter Usage
- **`woowa_search_pct_searches_with_filters`** / **`global_search_pct_searches_with_filters`**: % of searches using filters
- **`woowa_search_ctr_with_filters`** / **`global_search_ctr_with_filters`**: CTR when filters applied
- **`woowa_search_ctr_without_filters`** / **`global_search_ctr_without_filters`**: CTR without filters

### Session Engagement
- **`woowa_search_avg_searches_per_session`** / **`global_search_avg_searches_per_session`**: Avg searches per user
- **`woowa_search_pct_multi_search_sessions`** / **`global_search_pct_multi_search_sessions`**: % sessions with 2+ searches

### Comparison
- **`ctr_pct_change`**: % change in CTR (Global Search vs Woowa Search)
- **`cvr_pct_change`**: % change in CVR
- **`search_volume_diff`**: Absolute search volume difference
- **`ctr_statistically_significant`**: Is difference real? (Yes/No)

---

## 🎯 How to Interpret Results

### Scenario 1: Healthy Global Search Performance ✅
```
search_vertical: ALL
woowa_search_total_searches: 150,000
woowa_search_ctr: 0.0950
woowa_search_cvr: 0.0400

global_search_total_searches: 120,000
global_search_ctr: 0.1100 (+15.79%)
global_search_cvr: 0.0450 (+12.50%)
ctr_statistically_significant: Yes
```

**Interpretation:**
- ✅ Global Search has higher CTR and CVR (both statistically significant)
- ✅ Lower search volume but better quality
- ✅ Users finding what they need faster

---

### Scenario 2: Volume Migration in Progress 📊
```
search_vertical: BAEMIN_DELIVERY
woowa_search_total_searches: 200,000
global_search_total_searches: 80,000
search_volume_pct_change: -60%
```

**Interpretation:**
- Global Search still receiving less traffic (migration in progress)
- Need to monitor as volume increases
- Performance may change with scale

---

### Scenario 3: NULL Vertical Alert ⚠️
```
search_vertical: NULL_VERTICAL
woowa_search_ctr: 0.6500
woowa_search_cvr: 0.7496

global_search_ctr: 0.6200 (-4.62%)
global_search_cvr: 0.7201 (-3.95%)
ctr_statistically_significant: No
```

**Interpretation:**
- ⚠️ NULL vertical (old Woowa) has exceptionally high CVR (~75%!)
- ⚠️ Slight drop in Global Search but not statistically significant (yet)
- 🔍 Monitor closely - this traffic is highly valuable
- 💡 May need different ranking strategy for this segment

---

## 📋 Recommended Analysis Flow

### 1. **Start with Overall Query** (This one!)
Check high-level health:
- Is overall CTR/CVR better or worse?
- Are differences statistically significant?
- What's the search volume distribution?

### 2. **If Issues Found → Use Detailed Query**
Drill down to find:
- Which specific search terms are underperforming?
- Are issues concentrated in high-frequency or low-frequency terms?
- What's the click rank distribution for problematic queries?

### 3. **Export Both for Reporting**
- **Overall**: Executive summary, weekly metrics
- **Detailed**: Deep-dive analysis, action items

---

## 🔍 Key Insights to Look For

### Volume Distribution
```sql
-- What % of traffic is in each vertical?
woowa_search_total_searches by vertical:
- ALL: 40%
- BAEMIN_DELIVERY: 50%
- NULL_VERTICAL: 10%
```

### Click Rank Quality
```sql
-- What % of clicks are in top 3 positions?
Target: >60% in positions 1-3

woowa_search_pct_clicks_pos_1: 42%
woowa_search_pct_clicks_pos_2_3: 23%
= 65% in top 3 ✅ Good!
```

### Filter Dependency
```sql
-- Are users relying on filters?
woowa_search_pct_searches_with_filters: 25%
woowa_search_ctr_with_filters: 0.15
woowa_search_ctr_without_filters: 0.08

= 87.5% CTR lift with filters
= High filter dependency ⚠️
```

### Session Engagement
```sql
-- Are users struggling to find what they want?
woowa_search_avg_searches_per_session: 1.8
woowa_search_pct_multi_search_sessions: 45%

vs

global_search_avg_searches_per_session: 1.4 (-22%)
global_search_pct_multi_search_sessions: 32%

= AWS users find what they need faster ✅
```

---

## ⚠️ Important Notes

### 1. No "Global Search ≥5 searches" Filter
Unlike the detailed query, this aggregates **ALL searches** regardless of Global Search volume.

**Why?** We want the true overall picture, not filtered.

### 2. NULL_VERTICAL Special Handling
- NULL vertical has ~75% CVR (10x higher than other verticals!)
- Represents old Woowa search traffic
- Small volume but high value
- Monitor separately - different user behavior

### 3. Statistical Significance Still Applies
Even with high volumes, check the `_statistically_significant` columns.

---

## 📊 Sample Output Interpretation

### Example Output:
```
search_vertical: ALL
woowa_search_total_searches: 125,340
woowa_search_ctr: 0.0985
woowa_search_cvr: 0.0412
woowa_search_avg_click_rank: 3.2
woowa_search_pct_clicks_pos_1: 38%
woowa_search_pct_clicks_pos_2_3: 24%

global_search_total_searches: 89,250
global_search_ctr: 0.1123 (+14.01%)
global_search_cvr: 0.0465 (+12.86%)
global_search_avg_click_rank: 2.5 (-0.7)
global_search_pct_clicks_pos_1: 48% (+10 percentage points)
global_search_pct_clicks_pos_2_3: 26% (+2 percentage points)

ctr_statistically_significant: Yes
cvr_statistically_significant: Yes
```

### What This Tells You:

**✅ Wins:**
1. **CTR up 14%** (statistically significant)
2. **CVR up 13%** (statistically significant)
3. **Better ranking** - users clicking 0.7 positions higher
4. **More clicks at #1** - 48% vs 38% (10pp improvement!)
5. **74% of clicks in top 3** positions (48% + 26%)

**📊 Context:**
- Global Search has 71% of Woowa Search volume (89K vs 125K)
- Migration still in progress
- Performance improvements are real (statistically significant)

**🎯 Recommendation:**
- Continue migration - Global Search performing better
- Monitor as volume scales
- Track NULL_VERTICAL separately

---

## 🚀 Quick Start

### 1. Copy the Query
```bash
pbcopy < ~/woowa_search_analysis/overall_comparison_query.sql
```

### 2. Change Dates (Lines 4-5)
```sql
DECLARE start_date DATE DEFAULT CURRENT_DATE() - 1;
DECLARE end_date DATE DEFAULT CURRENT_DATE() - 1;
```

### 3. Run in BigQuery

### 4. Export Results
You'll get 3 rows - one per vertical - perfect for reporting!

---

## 📅 Recommended Cadence

- **Daily**: Monitor overall CTR/CVR
- **Weekly**: Track trends, check statistical significance
- **Monthly**: Deep dive with detailed query

---

## 💡 Pro Tips

1. **Compare week-over-week**: Run for last week and week before
2. **Track trends**: Export to sheets, create line charts
3. **Alert on drops**: If CTR drops >5% and significant, investigate
4. **Monitor NULL vertical**: High CVR segment - don't let it drop!
5. **Use with detailed query**: Overall for "what", detailed for "why"

---

## 🔗 Related Files

- **Detailed Query**: `comprehensive_comparison_query.sql` (per-term analysis)
- **Main README**: `README.md` (package overview)
- **Column Reference**: `query_output_columns_reference.md`

---

## 📝 Last Updated
May 27, 2026
