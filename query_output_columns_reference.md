# Query Output Columns - Quick Reference

**⚠️ Query Filters:**
- Only shows results where **AWS has ≥5 searches**
- Includes **NULL_VERTICAL** (old Woowa search with ~75% CVR)
- Excludes **BAEMIN_TAKEOUT** (not served by Global Search)

## 🔍 Identifying Columns

| Column | Description |
|--------|-------------|
| `search_vertical` | Which source: ALL (mixed tab), BAEMIN_DELIVERY (delivery tab), NULL_VERTICAL (old Woowa ~75% CVR!) |
| `search_query` | The search term (e.g., "birthday cake") |
| `search_popularity` | High Frequency (100+) / Medium Frequency (20-99) / Low Frequency (<20) |

---

## 📊 Woowa Search Metrics (Baseline)

### Volume & Quality
| Column | What It Means | Good Value |
|--------|---------------|------------|
| `woowa_search_searches` | Total searches | N/A (volume metric) |
| `woowa_search_unique_sessions` | Unique user sessions | N/A (volume metric) |
| `woowa_search_avg_results` | Avg vendors shown per search | 20-50 |
| `woowa_search_zero_results` | Searches with 0 results | 0 (lower is better) |
| `woowa_search_zrr` | Zero Result Rate (%) | <5% |

### Funnel Metrics
| Column | What It Means | Good Value |
|--------|---------------|------------|
| `woowa_search_ctr` | Click-Through Rate | >10% (>0.1000) |
| `woowa_search_cvr` | Conversion Rate | 3-8% (0.03-0.08) |

### Pagination Analysis
| Column | What It Means | Good Value |
|--------|---------------|------------|
| `woowa_search_pagination_rate` | % users who scrolled | <15% |
| `woowa_search_ctr_with_pagination` | CTR when user scrolled | Lower than without* |
| `woowa_search_ctr_without_pagination` | CTR when user didn't scroll | Higher is better |

*If CTR is higher WITH pagination, it means initial results are poor.

### Click Rank Distribution
| Column | What It Means | Good Value |
|--------|---------------|------------|
| `woowa_search_avg_click_rank` | Avg position clicked | <3.0 |
| `woowa_search_clicks_pos_1` | Clicks on #1 position | 40%+ of total clicks |
| `woowa_search_clicks_pos_2_3` | Clicks on positions 2-3 | 25%+ of total clicks |
| `woowa_search_clicks_pos_4_10` | Clicks on positions 4-10 | <25% of total clicks |
| `woowa_search_clicks_pos_11_plus` | Clicks beyond position 10 | <10% of total clicks |

### Filter Usage
| Column | What It Means | Good Value |
|--------|---------------|------------|
| `woowa_search_searches_with_filters` | Count of filtered searches | N/A |
| `woowa_search_ctr_with_filters` | CTR when filter used | Should be > without |
| `woowa_search_ctr_without_filters` | CTR raw search | Baseline |

### Session Metrics
| Column | What It Means | Good Value |
|--------|---------------|------------|
| `woowa_search_avg_searches_per_session` | Avg searches per user | 1.2-1.5 |
| `woowa_search_multi_search_sessions` | Sessions with 2+ searches | <40% of sessions |

---

## 🚀 Global Search Metrics (Test System)

Same columns as Woowa Search, but prefixed with `global_search_` instead of `woowa_search_`:

- `global_search_searches`, `global_search_ctr`, `global_search_cvr`, etc.

---

## 📈 Comparison Metrics (Global Search vs Woowa Search)

| Column | What It Means | How to Read |
|--------|---------------|-------------|
| `ctr_pct_change` | % change in CTR | +15% = Global Search is 15% better |
| `cvr_pct_change` | % change in CVR | -10% = Global Search is 10% worse |
| `zrr_pct_change` | % change in ZRR | -20% = Global Search has 20% fewer zero results (good!) |
| `pagination_rate_pct_change` | % change in pagination | +25% = More scrolling in Global Search (could be bad) |
| `avg_click_rank_diff` | Difference in click rank | -0.5 = Global Search clicks are 0.5 positions higher (better) |
| `filter_ctr_pct_change` | % change in filter CTR | +10% = Filters work better in Global Search |
| `searches_per_session_pct_change` | % change in searches/session | -15% = Fewer searches needed in Global Search (better) |

---

## ✅ Statistical Significance

| Column | Possible Values | What It Means |
|--------|----------------|---------------|
| `ctr_statistically_significant` | Yes / No / Insufficient Data / N/A | Whether CTR difference is real (95% confidence) |
| `cvr_statistically_significant` | Yes / No / Insufficient Data / N/A | Whether CVR difference is real (95% confidence) |

**"Yes"** = Difference is statistically significant (not due to chance)
**"No"** = Difference could be random variation
**"Insufficient Data"** = Less than 30 searches in either group
**"N/A"** = Data missing for one or both groups

---

## 🎯 How to Read a Row

### Example Row:
```
search_vertical: BAEMIN_DELIVERY
search_query: birthday cake
search_popularity: High Frequency
woowa_search_searches: 450
woowa_search_ctr: 0.1200 (12%)
woowa_search_avg_click_rank: 2.3
woowa_search_clicks_pos_1: 150
woowa_search_pagination_rate: 0.0800 (8%)
woowa_search_avg_searches_per_session: 1.3

global_search_searches: 520
global_search_ctr: 0.1478 (14.78%)
global_search_avg_click_rank: 1.8
global_search_clicks_pos_1: 210
global_search_pagination_rate: 0.0600 (6%)
global_search_avg_searches_per_session: 1.2

ctr_pct_change: +23.17%
avg_click_rank_diff: -0.5
pagination_rate_pct_change: -25.00%
searches_per_session_pct_change: -7.69%
ctr_statistically_significant: Yes
```

### Interpretation:
✅ **Global Search is performing significantly better:**
- 23% higher CTR (statistically significant)
- Users clicking 0.5 positions higher on average
- 25% less scrolling needed
- 7.7% fewer searches per session (users find what they want faster)

This is a **HIGH IMPACT WIN** for Global Search! 🎉

---

## 🚨 Red Flags to Watch For

### Critical Issues (Fix Immediately):
- `woowa_search_zrr > 0.10` (>10% zero results)
- `woowa_search_ctr < 0.05` (<5% CTR) on High Frequency terms
- `woowa_search_avg_click_rank > 5.0` (poor ranking)
- `woowa_search_clicks_pos_1 < 20%` of total clicks

### Warning Signs (Investigate):
- `ctr_pct_change` negative on High Frequency terms
- `woowa_search_ctr_with_pagination > woowa_search_ctr_without_pagination` (ranking issue)
- `woowa_search_avg_searches_per_session > 2.0` (user struggle)
- `cvr_statistically_significant: Yes` with negative change

### Positive Signals (Celebrate):
- `ctr_pct_change > 20%` with "Yes" significance
- `avg_click_rank_diff < -0.5` (clicking higher)
- `pagination_rate_pct_change < -20%` (less scrolling needed)
- `searches_per_session_pct_change < -10%` (more efficient)

---

## 📊 Sorting Recommendations

### To Find Top Wins:
```sql
ORDER BY ctr_pct_change DESC, woowa_search_searches DESC
```
= Biggest CTR improvements on high-volume searches

### To Find Critical Issues:
```sql
WHERE woowa_search_zrr > 0.10 OR woowa_search_ctr < 0.05
ORDER BY woowa_search_searches DESC
```
= High-impact broken searches

### To Find Ranking Problems:
```sql
WHERE woowa_search_avg_click_rank > 4.0
ORDER BY woowa_search_searches DESC
```
= Poor ranking on high-volume terms

---

## 💾 Export Tips

When exporting to sheets/Excel:

1. **Add Conditional Formatting**:
   - Green: `ctr_pct_change > 10%`
   - Red: `ctr_pct_change < -10%`
   - Yellow: `ctr_statistically_significant = "Insufficient Data"`

2. **Create Pivot Tables** by:
   - `search_vertical` (compare verticals)
   - `search_popularity` (compare frequency tiers)

3. **Freeze Panes**:
   - Freeze first 3 columns (vertical, query, popularity)

4. **Filter Views**:
   - High Frequency only
   - Statistically significant only
   - Positive CTR changes only
