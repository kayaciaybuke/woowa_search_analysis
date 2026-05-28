# Comprehensive Woowa Search Comparison Query - Dimensions Guide

## 📊 All Dimensions Included

The enhanced query now includes ALL the requested dimensions. Here's what each one tells you:

**⚠️ Important Filters Applied:**
- ✅ Only shows results where **Global Search has ≥5 searches** (reduces noise)
- ✅ Includes **NULL vertical** (old Woowa search with ~75% CVR!)
- ✅ Excludes **BAEMIN_TAKEOUT** (not served by Global Search)

---

## 1. 📜 **Pagination Analysis**
**Question:** Do users who scroll past the first page behave differently?

### Metrics Provided:
- **`woowa_search_pagination_rate`** / **`global_search_pagination_rate`**: % of searches where user scrolled past initial results
- **`woowa_search_ctr_with_pagination`** / **`global_search_ctr_with_pagination`**: CTR for searches where user scrolled
- **`woowa_search_ctr_without_pagination`** / **`global_search_ctr_without_pagination`**: CTR for searches where user didn't scroll
- **`pagination_rate_pct_change`**: % change in pagination rate between systems

### What to Look For:
- ✅ **Higher CTR with pagination** = Good initial results (users click before scrolling)
- ⚠️ **Higher CTR without pagination** = Users need to scroll to find what they want (bad ranking)
- 📈 **Increased pagination rate** = Could mean worse initial results OR more engagement

---

## 2. 🎯 **Click Rank Distribution**
**Question:** Which positions are users clicking most?

### Metrics Provided:
- **`woowa_search_avg_click_rank`** / **`global_search_avg_click_rank`**: Average position of clicked vendors
- **`woowa_search_clicks_pos_1`** / **`global_search_clicks_pos_1`**: Number of clicks on #1 position
- **`woowa_search_clicks_pos_2_3`** / **`global_search_clicks_pos_2_3`**: Clicks on positions 2-3
- **`woowa_search_clicks_pos_4_10`** / **`global_search_clicks_pos_4_10`**: Clicks on positions 4-10
- **`woowa_search_clicks_pos_11_plus`** / **`global_search_clicks_pos_11_plus`**: Clicks beyond position 10
- **`avg_click_rank_diff`**: Difference in average click rank

### What to Look For:
- ✅ **Lower avg click rank** = Better ranking (relevant results at top)
- ✅ **More clicks on position 1** = Excellent ranking quality
- ⚠️ **High clicks on position 11+** = Poor ranking (users digging deep)
- 🎯 **Target**: >40% of clicks in top 3 positions

**Example Interpretation:**
```
woowa_search_clicks_pos_1: 150
woowa_search_clicks_pos_2_3: 180
woowa_search_clicks_pos_4_10: 120
woowa_search_clicks_pos_11_plus: 50
```
= 30% position 1, 36% positions 2-3, 24% positions 4-10, 10% beyond 10
= **Good ranking** (66% of clicks in top 3)

---

## 3. 🔍 **Filter Usage Analysis**
**Question:** How do filters impact search performance?

### Metrics Provided:
- **`woowa_search_searches_with_filters`** / **`global_search_searches_with_filters`**: Number of searches where filters were applied
- **`woowa_search_ctr_with_filters`** / **`global_search_ctr_with_filters`**: CTR when filters are used
- **`woowa_search_ctr_without_filters`** / **`global_search_ctr_without_filters`**: CTR for raw searches (no filters)
- **`filter_ctr_pct_change`**: % change in filter CTR between systems

### What to Look For:
- ✅ **Higher CTR with filters** = Filters help users find what they want
- ⚠️ **Lower CTR with filters** = Either filters are too restrictive OR initial results are already good
- 📊 **High filter usage** = Could indicate users aren't finding what they want initially

**Filter Impact Formula:**
```
Filter Impact = (CTR_with_filters - CTR_without_filters) / CTR_without_filters * 100
```

---

## 4. 👥 **Session-Level Metrics**
**Question:** How many searches do users perform per session?

### Metrics Provided:
- **`woowa_search_avg_searches_per_session`** / **`global_search_avg_searches_per_session`**: Average searches per session
- **`woowa_search_multi_search_sessions`** / **`global_search_multi_search_sessions`**: Sessions with 2+ searches
- **`woowa_search_unique_sessions`** / **`global_search_unique_sessions`**: Total unique sessions
- **`searches_per_session_pct_change`**: % change in searches per session

### What to Look For:
- ✅ **Lower searches per session** = Users find what they want on first search (good)
- ⚠️ **Higher searches per session** = Users struggling to find results (bad) OR high engagement (could be good)
- 📊 **Context matters**: 
  - **Low CTR + High searches/session** = Users struggling 😞
  - **High CTR + High searches/session** = High engagement 😊

**Benchmark:**
- Avg searches per session: **1.2 - 1.5** = Healthy
- Avg searches per session: **2.0+** = Users struggling OR exploring

---

## 5. 🔥 **Search Term Popularity**
**Question:** Does performance differ for popular vs rare search terms?

### Metrics Provided:
- **`search_popularity`**: Categorizes searches into:
  - **High Frequency**: 100+ searches in time period
  - **Medium Frequency**: 20-99 searches
  - **Low Frequency**: <20 searches (long-tail)

### What to Look For:
- ✅ **High CTR on high-frequency terms** = Core search experience is good
- ⚠️ **Low CTR on high-frequency terms** = Major issue (affects many users)
- 📊 **Low CTR on low-frequency terms** = Expected (long-tail is hard)

**Strategy:**
- **High Frequency**: Must perform well (affects most users)
- **Medium Frequency**: Good opportunity for improvement
- **Low Frequency**: Don't over-optimize (diminishing returns)

---

## 6. 📊 **All Core Metrics**

### Result Quality:
- **`woowa_search_avg_results`** / **`global_search_avg_results`**: Average vendors shown
- **`woowa_search_zero_results`** / **`global_search_zero_results`**: Count of searches with 0 results
- **`woowa_search_zrr`** / **`global_search_zrr`**: Zero Result Rate (%)

### Funnel Metrics:
- **`woowa_search_searches`** / **`global_search_searches`**: Total searches
- **`woowa_search_ctr`** / **`global_search_ctr`**: Click-Through Rate
- **`woowa_search_cvr`** / **`global_search_cvr`**: Conversion Rate

### Search Vertical:
- **`search_vertical`**: ALL, BAEMIN_DELIVERY, NULL_VERTICAL
  - **ALL**: Mixed Results Tab (all vendors)
  - **BAEMIN_DELIVERY**: Delivery Results Tab
  - **NULL_VERTICAL**: Old Woowa Search (high CVR ~75%!)
  - **Note**: BAEMIN_TAKEOUT excluded (not served by Global Search)

---

## 📈 Output Example

Here's what the comprehensive output looks like:

| search_vertical | search_query | search_popularity | woowa_search_searches | woowa_search_ctr | woowa_search_cvr | woowa_search_avg_click_rank | woowa_search_clicks_pos_1 | global_search_searches | global_search_ctr | global_search_cvr | ctr_pct_change | ctr_significant |
|----------------|--------------|-------------------|---------------------|----------------|----------------|---------------------------|-------------------------|-------------------|----------------|----------------|----------------|----------------|
| ALL | birthday cake | High Frequency | 450 | 0.1200 | 0.0533 | 2.3 | 150 | 520 | 0.1478 | 0.0609 | +23.17% | Yes |
| BAEMIN_DELIVERY | pizza | High Frequency | 680 | 0.0950 | 0.0450 | 3.5 | 180 | 740 | 0.1100 | 0.0520 | +15.79% | Yes |
| NULL_VERTICAL | chicken | High Frequency | 320 | 0.6500 | 0.7496 | 1.8 | 180 | 85 | 0.6200 | 0.7200 | -4.62% | No |

---

## 🎯 How to Interpret Combined Metrics

### Scenario 1: Good Ranking Quality
```
avg_click_rank: 1.8
clicks_pos_1: 45%
ctr_with_pagination < ctr_without_pagination
```
= **Excellent ranking** - Users find what they want at the top

### Scenario 2: Poor Ranking Quality
```
avg_click_rank: 5.2
clicks_pos_1: 15%
pagination_rate: 35%
```
= **Poor ranking** - Users have to dig to find results

### Scenario 3: Filter Dependency
```
ctr_without_filters: 0.05
ctr_with_filters: 0.15
searches_with_filters: 40% of total
```
= **Users rely on filters** - Initial results not targeted enough

### Scenario 4: User Struggle
```
avg_searches_per_session: 2.5
ctr: 0.08
zrr: 0.15
```
= **Users struggling** - High searches, low CTR, high zero results

### Scenario 5: High Engagement
```
avg_searches_per_session: 2.2
ctr: 0.18
cvr: 0.08
```
= **High engagement** - Users searching multiple times AND converting

---

## 🔧 Easy Date Configuration

At the top of the query, just change:

```sql
-- For single day analysis:
DECLARE start_date DATE DEFAULT CURRENT_DATE() - 1;
DECLARE end_date DATE DEFAULT CURRENT_DATE() - 1;

-- For week analysis:
DECLARE start_date DATE DEFAULT CURRENT_DATE() - 7;
DECLARE end_date DATE DEFAULT CURRENT_DATE() - 1;

-- For specific date range:
DECLARE start_date DATE DEFAULT '2026-05-20';
DECLARE end_date DATE DEFAULT '2026-05-26';
```

---

## 🎓 Key Performance Indicators (KPIs)

### Must Monitor:
1. **CTR** - Should be >10% for healthy search
2. **ZRR** - Should be <5% for good coverage
3. **Avg Click Rank** - Should be <3.0 for good ranking
4. **% Clicks Position 1-3** - Should be >60%
5. **Searches per Session** - Should be 1.2-1.5

### Nice to Have:
6. **Pagination Rate** - <15% is good
7. **Filter CTR Lift** - Positive is good (filters help)
8. **CVR** - Business dependent, usually 3-8%

---

## 💡 Analysis Tips

1. **Start with High-Frequency Terms**: Biggest impact
2. **Look for Patterns**: Is issue consistent across verticals?
3. **Check Statistical Significance**: Don't act on small samples
4. **Compare Similar Searches**: Control for search intent
5. **Monitor Trends**: Track week-over-week changes

---

## 🚀 Next Steps After Running Query

1. **Identify Top Issues**:
   - High ZRR terms
   - Low CTR on high-frequency searches
   - Poor click rank distribution

2. **Deep Dive**:
   - Export top/bottom 20 search terms
   - Analyze vendor ordering for problematic queries
   - Check if filters improve results

3. **Prioritize**:
   - Fix high-frequency, low-performing terms first
   - Address zero-result searches
   - Optimize top 3 positions

4. **Track Impact**:
   - Re-run query weekly
   - Monitor CTR/CVR trends
   - Validate improvements are statistically significant
