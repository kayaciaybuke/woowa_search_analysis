# Woowa Search Analysis - Query Package

## 📦 What's Included

This folder contains queries for **two types of analysis**:

### 🔵 Platform Comparison (Woowa vs Global Search)
Compare old Woowa Search platform vs new Global Search platform.

### 🟢 AB Test Analysis (Control vs Treatment)  
Compare Control vs Treatment variations using Eppo assignment data during active AB test.

---

## Main Queries

### Platform Comparison Queries

1. **`overall_comparison_query.sql`** 🎯 **EXECUTIVE SUMMARY**
   - High-level aggregate view across ALL searches
   - 3 rows (one per vertical: ALL, BAEMIN_DELIVERY, NULL_VERTICAL)
   - Perfect for weekly reports & trends
   - Use this for: "How is Global Search performing overall?"

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

### AB Test Queries (NEW!)

4. **`overall_comparison_query_ab_test.sql`** 🎯 **AB TEST SUMMARY**
   - Control vs Treatment overall performance
   - 2-3 rows (by vertical: ALL, BAEMIN_DELIVERY only)
   - **Requires:** Yesterday's data (D+1 lag)
   - Use this for: "How is the AB test performing?"

5. **`head_torso_tail_comparison_query_ab_test.sql`** 📊 **AB TEST BY TIER**
   - Control vs Treatment by frequency tier
   - 6-9 rows (2-3 verticals × 3 tiers)
   - **Requires:** Yesterday's data (D+1 lag)
   - Use this for: "Which tier wins in the AB test?"

6. **`comprehensive_comparison_query_ab_test.sql`** 🔍 **AB TEST DETAILED**
   - Control vs Treatment per search query
   - Hundreds/thousands of rows
   - **Requires:** Yesterday's data (D+1 lag)
   - Use this for: "Which queries are winning/losing?"

**⚠️ AB Test Important:** All AB test queries require yesterday's data due to D+1 assignment lag. See `AB_TEST_QUICK_START.md` for details.

### Guides & Documentation

**AB Test:**
- **`AB_TEST_QUICK_START.md`** 🆕
  - AB test vs platform comparison decision guide
  - D+1 lag requirement explained
  - Assignment table structure
  - Common mistakes to avoid

**Platform Comparison:**
- **`OVERALL_COMPARISON_GUIDE.md`**
  - How to use the overall query
  - Interpreting aggregate metrics
  - Example scenarios

- **`HEAD_TORSO_TAIL_GUIDE.md`**
  - Understanding Head/Torso/Tail performance
  - Optimization strategies by tier
  - Volume distribution analysis

**Reference:**
- **`comprehensive_query_dimensions_guide.md`**
  - Explains every metric in detail
  - How to interpret results
  - What good vs bad looks like

- **`query_output_columns_reference.md`**
  - Quick reference for all output columns
  - Column-by-column explanation
  - Red flags to watch for

- **`woowa_search_query_guide.md`**
  - Complete guide to the query package
  - Sample queries
  - Field documentation

- **`CHANGELOG.md`**
  - Latest changes and updates
  - Why each change was made

- **`sample_perseus_data.sql`**
  - Query to explore your data first
  - See what fields are available

**Technical Details:**
- **`CLICK_POSITION_TRACKING_HACK.md`** ⚠️ **IMPORTANT**
  - Why click positions reset by delivery status
  - How we calculate accurate positions using `shopsIds`
  - Pagination handling and known issues
  - Open questions for tracking team
  - **Read this if you're modifying position calculations**

---

## 🤔 Which Query Should I Use?

### First: Platform Comparison vs AB Test?

**Use Platform Comparison queries when:**
- ✅ Comparing Woowa Search vs Global Search platforms
- ✅ Multi-day trends (7+ days)
- ✅ Historical analysis before AB test launch
- ✅ Includes NULL_VERTICAL traffic

**Use AB Test queries when:**
- ✅ Comparing Control vs Treatment during active AB test
- ✅ Yesterday's data only (D+1 lag requirement)
- ✅ Analyzing assigned users with exposure gating
- ✅ Validating AB test traffic split

### Platform Comparison Queries

#### Use **Overall Comparison Query** When:
- ✅ Creating weekly/monthly reports
- ✅ Monitoring high-level trends
- ✅ Presenting to executives
- ✅ Quick health check
- ✅ Tracking overall CTR/CVR changes
- **Output:** 3 rows (ALL, BAEMIN_DELIVERY, NULL_VERTICAL)

#### Use **Head/Torso/Tail Query** When:
- ✅ Understanding performance by search popularity
- ✅ Strategic optimization planning
- ✅ Identifying which tier needs attention
- ✅ Volume distribution analysis
- ✅ Checking if Head searches perform best
- **Output:** 9 rows (3 verticals × 3 tiers)

#### Use **Detailed Comparison Query** When:
- ✅ Finding specific problematic search terms
- ✅ Deep-dive analysis
- ✅ Understanding which queries drive metrics
- ✅ Prioritizing optimization work
- ✅ Analyzing individual search behavior
- **Output:** Hundreds/thousands of rows (one per search term)

### AB Test Queries

#### Use **AB Test Overall Query** When:
- ✅ Daily AB test check-in
- ✅ Validating traffic split (~50/50)
- ✅ Quick Control vs Treatment comparison
- ✅ Checking for significant differences
- **Output:** 2-3 rows (ALL, BAEMIN_DELIVERY only)
- **⚠️ Requirement:** Yesterday's data (D+1 lag)

#### Use **AB Test Head/Torso/Tail Query** When:
- ✅ Understanding which tier wins/loses
- ✅ Strategic AB test insights
- ✅ Checking if Head tier performs better
- ✅ Tier-specific optimization planning
- **Output:** 6-9 rows (2-3 verticals × 3 tiers)
- **⚠️ Requirement:** Yesterday's data (D+1 lag)

#### Use **AB Test Detailed Query** When:
- ✅ Finding which queries win/lose
- ✅ Deep-dive AB test analysis
- ✅ Investigating specific search term issues
- ✅ Validating treatment improvements
- **Output:** Hundreds/thousands of rows (one per search query)
- **⚠️ Requirement:** Yesterday's data (D+1 lag)

### Recommended Workflows

**Platform Comparison:**
1. **Start with Overall** → Is there an issue? (e.g., "CTR dropped 5%")
2. **Run Head/Torso/Tail** → Which tier has the issue? (e.g., "Head CTR dropped")
3. **Use Detailed** → Which specific searches? (e.g., "pizza, chicken, burger")
4. **Export all three** → Overall for exec summary, H/T/T for strategy, Detailed for action items

**AB Test:**
1. **Start with Overall AB Test** → Is Treatment winning? (e.g., "+8% CTR, significant")
2. **Check traffic split** → Is it ~50/50? (e.g., "50.2% treatment traffic")
3. **Run Head/Torso/Tail AB Test** → Which tier wins? (e.g., "Head +12%, Torso +5%")
4. **Use Detailed AB Test** → Which queries win/lose? (e.g., "Top 10 wins, Top 10 losses")
5. **Validate before shipping** → Ensure consistent improvements across tiers

---

## 🚀 Quick Start

### Option A: Platform Comparison (Woowa vs Global Search)

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
- You'll get 3 rows (ALL, BAEMIN_DELIVERY, NULL_VERTICAL)
- Perfect for weekly reports!

**Date Options:**
```sql
-- For yesterday (recommended - complete data):
DECLARE start_date DATE DEFAULT CURRENT_DATE() - 1;
DECLARE end_date DATE DEFAULT CURRENT_DATE() - 1;

-- For last 7 days:
DECLARE start_date DATE DEFAULT CURRENT_DATE() - 7;
DECLARE end_date DATE DEFAULT CURRENT_DATE() - 1;

-- For specific date range:
DECLARE start_date DATE DEFAULT DATE '2026-05-20';
DECLARE end_date DATE DEFAULT DATE '2026-05-26';
```

---

### Option B: AB Test Analysis (Control vs Treatment)

**⚠️ IMPORTANT: Must use yesterday's data (D+1 lag)**

**Step 1: Open the AB Test Overall Query**
```bash
open ~/woowa_search_analysis/overall_comparison_query_ab_test.sql
```

**Step 2: Verify Date (Line 6)**
```sql
DECLARE report_date DATE DEFAULT CURRENT_DATE() - 1;  -- Always yesterday!
```

**Step 3: Run in BigQuery**
- You'll get 2-3 rows (ALL, BAEMIN_DELIVERY only)
- Check `treatment_traffic_pct` (should be ~50%)
- Perfect for daily AB test check-ins!

**Date Options for AB Test:**
```sql
-- ✅ CORRECT: Yesterday (D+1 lag)
DECLARE report_date DATE DEFAULT CURRENT_DATE() - 1;

-- ✅ CORRECT: Specific past date
DECLARE report_date DATE DEFAULT DATE '2026-05-27';

-- ❌ WRONG: Today (incomplete assignments)
DECLARE report_date DATE DEFAULT CURRENT_DATE();
```

**📖 For more AB test details:** See `AB_TEST_QUICK_START.md`

---

### Option C: Detailed Analysis (Deep Dive)

**For Platform Comparison:**
```bash
open ~/woowa_search_analysis/comprehensive_comparison_query.sql
```

**For AB Test:**
```bash
open ~/woowa_search_analysis/comprehensive_comparison_query_ab_test.sql
```

- You'll get hundreds/thousands of rows
- One row per search term/query
- Filter for high-volume searches first

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
May 28, 2026

## 🏷️ Version
v3.0 - Added AB Test queries with Eppo assignment integration
- ✅ AB Test: Control vs Treatment comparison
- ✅ D+1 lag support for assignment data
- ✅ Unified tier calculation across variations
- ✅ Traffic split validation
- ✅ Platform Comparison: Woowa vs Global Search (existing)

## 🔗 Related Resources

**Assignment Table Script:**
`/Users/k.musina/Desktop/analytics/gs_woowa_eppo_assignments.sql`

**Workflow Documentation:**
`/Users/aybueke.kayaci/dh-pm-claude-skills/workflows/woowa-ab-test-analysis.md`

**Assignment Table:** 
`dhub-gd-analytics.eppo_input.gs_woowa_assignments`
