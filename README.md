# Woowa Search Analysis - Query Package

## 📦 What's Included

This folder contains everything you need to compare **Old Woowa Search** vs **Global Search** performance.

### Main Queries:

1. **`overall_comparison_query.sql`** 🎯 **EXECUTIVE SUMMARY**
   - High-level aggregate view across ALL searches
   - 3 rows (one per vertical)
   - Perfect for weekly reports & trends
   - Use this for: "How is AWS performing overall?"

2. **`head_torso_tail_comparison_query.sql`** 📊 **TIER BREAKDOWN**
   - Performance by search frequency tier (Head/Torso/Tail)
   - 9 rows (3 verticals × 3 tiers)
   - Strategic optimization insights
   - Use this for: "Which tier needs attention?"

3. **`comprehensive_comparison_query.sql`** 🔍 **DETAILED ANALYSIS**
   - Per-search-term breakdown
   - Hundreds/thousands of rows
   - Deep-dive analysis
   - Use this for: "Which searches are underperforming?"

### Guides & Documentation:

4. **`OVERALL_COMPARISON_GUIDE.md`**
   - How to use the overall query
   - Interpreting aggregate metrics
   - Example scenarios

5. **`HEAD_TORSO_TAIL_GUIDE.md`**
   - Understanding Head/Torso/Tail performance
   - Optimization strategies by tier
   - Volume distribution analysis

6. **`comprehensive_query_dimensions_guide.md`**
   - Explains every metric in detail
   - How to interpret results
   - What good vs bad looks like

7. **`query_output_columns_reference.md`**
   - Quick reference for all output columns
   - Column-by-column explanation
   - Red flags to watch for

8. **`woowa_search_query_guide.md`**
   - Complete guide to the query package
   - Sample queries
   - Field documentation

9. **`CHANGELOG.md`**
   - Latest changes and updates
   - Why each change was made

8. **`sample_perseus_data.sql`**
   - Query to explore your data first
   - See what fields are available

---

## 🤔 Which Query Should I Use?

### Use **Overall Comparison Query** When:
- ✅ Creating weekly/monthly reports
- ✅ Monitoring high-level trends
- ✅ Presenting to executives
- ✅ Quick health check
- ✅ Tracking overall CTR/CVR changes
- **Output:** 3 rows (one per vertical)

### Use **Head/Torso/Tail Query** When:
- ✅ Understanding performance by search popularity
- ✅ Strategic optimization planning
- ✅ Identifying which tier needs attention
- ✅ Volume distribution analysis
- ✅ Checking if Head searches perform best
- **Output:** 9 rows (3 verticals × 3 tiers)

### Use **Detailed Comparison Query** When:
- ✅ Finding specific problematic search terms
- ✅ Deep-dive analysis
- ✅ Understanding which queries drive metrics
- ✅ Prioritizing optimization work
- ✅ Analyzing individual search behavior
- **Output:** Hundreds/thousands of rows (one per search term)

### Recommended Workflow:
1. **Start with Overall** → Is there an issue? (e.g., "CTR dropped 5%")
2. **Run Head/Torso/Tail** → Which tier has the issue? (e.g., "Head CTR dropped")
3. **Use Detailed** → Which specific searches? (e.g., "pizza, chicken, burger")
4. **Export all three** → Overall for exec summary, H/T/T for strategy, Detailed for action items

---

## 🚀 Quick Start

### Option A: Overall Summary (Recommended First)

**Step 1: Open the Overall Query**
```bash
open ~/woowa_search_analysis/overall_comparison_query.sql
```

**Step 2: Change Dates (Lines 4-5)**
```sql
DECLARE start_date DATE DEFAULT CURRENT_DATE() - 1;  -- Yesterday
DECLARE end_date DATE DEFAULT CURRENT_DATE() - 1;    -- Yesterday
```

**Step 3: Run in BigQuery**
- You'll get 3 rows (one per vertical)
- Perfect for weekly reports!

---

### Option B: Detailed Analysis (When You Need Deep Dive)

**Step 1: Open the Detailed Query**
```bash
open ~/woowa_search_analysis/comprehensive_comparison_query.sql
```

**Step 2: Change Dates (Same as above)**

**Step 3: Run in BigQuery**
- You'll get hundreds/thousands of rows
- One row per search term
- Filter for high-frequency searches first

---

### Date Options:
```sql
-- For yesterday (recommended - complete data):
DECLARE start_date DATE DEFAULT CURRENT_DATE() - 1;
DECLARE end_date DATE DEFAULT CURRENT_DATE() - 1;

-- For today (may be incomplete):
DECLARE start_date DATE DEFAULT CURRENT_DATE();
DECLARE end_date DATE DEFAULT CURRENT_DATE();

-- For last 7 days:
DECLARE start_date DATE DEFAULT CURRENT_DATE() - 7;
DECLARE end_date DATE DEFAULT CURRENT_DATE() - 1;
```

---

## ⚠️ Important Query Filters

The query automatically applies these filters:

1. **Global Search Must Have ≥5 Searches**
   - Removes low-volume noise
   - Only shows statistically meaningful comparisons

2. **Includes NULL Vertical**
   - Old Woowa search traffic
   - Has exceptionally high CVR (~75%!)
   - Important to monitor

3. **Excludes BAEMIN_TAKEOUT**
   - Not served by Global Search
   - Ensures apples-to-apples comparison

---

## 📊 What You'll Get

### Search Verticals Analyzed:
- ✅ **ALL** - Mixed Results Tab
- ✅ **BAEMIN_DELIVERY** - Delivery Tab
- ✅ **NULL_VERTICAL** - Old Woowa Search (high CVR!)
- ❌ **BAEMIN_TAKEOUT** - Excluded (not in GS)

### Metrics Provided:
- **Volume**: Searches, sessions
- **Funnel**: CTR, CVR, ZRR
- **Quality**: Avg results, zero results
- **Engagement**: Pagination, click rank, filters
- **Session**: Searches per session, multi-search sessions
- **Comparison**: % change, statistical significance

---

## 🎯 Key Metrics to Watch

| Metric | Good Value | Red Flag |
|--------|------------|----------|
| CTR | >10% (>0.1000) | <5% |
| CVR | 3-8% (0.03-0.08) | <1% |
| ZRR | <5% | >10% |
| Avg Click Rank | <3.0 | >5.0 |
| Clicks Position 1-3 | >60% | <40% |

---

## 📈 Example Output

| search_vertical | search_query | woowa_search_searches | woowa_search_ctr | woowa_search_cvr | global_search_searches | global_search_ctr | global_search_cvr | ctr_pct_change | ctr_significant |
|-----------------|--------------|---------------------|----------------|----------------|-------------------|----------------|----------------|----------------|----------------|
| ALL | birthday cake | 450 | 0.1200 | 0.0533 | 520 | 0.1478 | 0.0609 | **+23.17%** | ✅ Yes |
| BAEMIN_DELIVERY | pizza | 680 | 0.0950 | 0.0450 | 740 | 0.1100 | 0.0520 | **+15.79%** | ✅ Yes |
| NULL_VERTICAL | chicken | 320 | 0.6500 | 0.7496 | 85 | 0.6200 | 0.7200 | **-4.62%** | ❌ No |

**Interpretation:**
- ✅ ALL & DELIVERY verticals: Global Search performing better (statistically significant)
- ⚠️ NULL_VERTICAL: Slight CVR drop but not statistically significant (need more data)

---

## 🔍 Special Note: NULL_VERTICAL

The NULL vertical represents **old Woowa search** and has:
- **Very high CVR** (~75%!)
- **Lower volume** in Global Search
- **Different user behavior** than other verticals

**Why this matters:**
- Could indicate different entry points (direct links vs search)
- May represent loyal/repeat customers
- Needs special attention - don't let CVR drop!

**Action:** Monitor NULL_VERTICAL separately and investigate if CVR drops significantly.

---

## 📝 Tips for Analysis

1. **Start with High Frequency terms** - Biggest impact
2. **Check statistical significance** - Don't act on small samples
3. **Compare similar searches** - Control for intent
4. **Look for patterns** - Is issue consistent across verticals?
5. **Export to sheets** - Use conditional formatting for quick insights

---

## 🆘 Need Help?

### Quick Answers:
- **"What does this column mean?"** → Check `query_output_columns_reference.md`
- **"How do I interpret this metric?"** → Check `comprehensive_query_dimensions_guide.md`
- **"What fields are available?"** → Run `sample_perseus_data.sql`
- **"What changed in the query?"** → Check `CHANGELOG.md`

### File Locations:
All files are in: `~/woowa_search_analysis/`

---

## 📅 Last Updated
May 27, 2026

## 🏷️ Version
v2.0 - Updated with NULL vertical support and AWS ≥5 filter
