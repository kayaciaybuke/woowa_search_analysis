# Woowa Search Analysis - AB Test Query Package

## 📦 What's Included

This folder contains queries for **AB Test Analysis** comparing Control (A) vs Treatment (B) variations during the Woowa AB test period (May 30 - June 17, 2026).

---

## Main Queries

### AB Test Analysis Queries

1. **`overall_comparison_query_ab_test.sql`** 🎯 **AB TEST SUMMARY**
   - Control vs Treatment overall performance
   - 2-3 rows (by vertical: ALL, BAEMIN_DELIVERY only)
   - Date range: May 30 - June 17, 2026 (inclusive)
   - Use this for: "How is the AB test performing?"

2. **`head_torso_tail_comparison_query_ab_test.sql`** 📊 **AB TEST BY TIER**
   - Control vs Treatment by frequency tier (Head/Torso/Tail)
   - 6-9 rows (2-3 verticals × 3 tiers)
   - Date range: May 30 - June 17, 2026 (inclusive)
   - Use this for: "Which tier wins in the AB test?"

3. **`comprehensive_comparison_query_ab_test.sql`** 🔍 **AB TEST DETAILED**
   - Control vs Treatment per search query
   - Hundreds/thousands of rows
   - Date range: May 30 - June 17, 2026 (inclusive)
   - Use this for: "Which queries are winning/losing?"

4. **`query_classification_breakdown_ab_test.sql`** 🏷️ **QUERY CLASSIFICATION BREAKDOWN**
   - Control vs Treatment by Vertical × Tier × Query Classification
   - Date range: May 30 - June 17, 2026 (inclusive)
   - Classifications: restaurant, item, cuisine, unclassified
   - Use this for: "How do different query types perform in AB test?"

5. **`exact_match_analysis_queries.sql`** 🎯 **EXACT MATCH ANALYSIS**
   - Restaurant query performance by exact match positioning
   - Order source tracking (exact match vendor vs others)
   - Last-click attribution model
   - Date range: May 30 - June 17, 2026 (inclusive)
   - Use this for: "How does exact match positioning affect conversion?"

**⚠️ Important:** All AB test queries use a fixed date range (May 30 - June 17, 2026) for consistent analysis.

---

## Guides & Documentation

### AB Test Analysis
- **`AB_TEST_QUICK_START.md`**
  - How to use AB test queries
  - Assignment table structure
  - Date range explanation
  - Common mistakes to avoid

- **`EXACT_MATCH_ANALYSIS_GUIDE.md`**
  - Exact match positioning analysis methodology
  - Order attribution tracking (exact match vs other vendors)
  - Key findings: 95.1% of rank_1 orders from exact match vendor
  - Technical notes on vendor ID matching

- **`QUERY_CLASSIFICATION_GUIDE.md`**
  - Query classification breakdown methodology
  - How to interpret classification results
  - Classification types explained

### Query Analysis Guides
- **`HEAD_TORSO_TAIL_GUIDE.md`**
  - Understanding Head/Torso/Tail performance
  - Optimization strategies by tier
  - Volume distribution analysis

- **`OVERALL_COMPARISON_GUIDE.md`**
  - How to use the overall query
  - Interpreting aggregate metrics
  - Example scenarios

### Reference Documentation
- **`comprehensive_query_dimensions_guide.md`**
  - Explains every metric in detail
  - How to interpret results
  - What good vs bad looks like

- **`query_output_columns_reference.md`**
  - Quick reference for all output columns
  - Column-by-column explanation
  - Red flags to watch for

- **`CHANGELOG.md`**
  - Latest changes and updates
  - Why each change was made

- **`DATA_FILTERING_CONSTRAINTS.md`**
  - Complete filter specifications
  - What data is included/excluded
  - Filter rationale and validation

### Technical Details
- **`CLICK_POSITION_TRACKING_HACK.md`** ⚠️ **IMPORTANT**
  - Why click positions reset by delivery status
  - How we calculate accurate positions using `shopsIds`
  - Pagination handling and known issues
  - **Read this if you're modifying position calculations**

---

## 🤔 Which Query Should I Use?

### Use **AB Test Overall Query** When:
- ✅ AB test summary analysis
- ✅ Validating traffic split (~50/50)
- ✅ Quick Control vs Treatment comparison
- ✅ Checking for significant differences
- **Output:** 2-3 rows (ALL, BAEMIN_DELIVERY only)
- **Date Range:** May 30 - June 17, 2026 (fixed)

### Use **AB Test Head/Torso/Tail Query** When:
- ✅ Understanding which tier wins/loses
- ✅ Strategic AB test insights
- ✅ Checking if Head tier performs better
- ✅ Tier-specific optimization planning
- **Output:** 6-9 rows (2-3 verticals × 3 tiers)
- **Date Range:** May 30 - June 17, 2026 (fixed)

### Use **AB Test Detailed Query** When:
- ✅ Finding which queries win/lose
- ✅ Deep-dive AB test analysis
- ✅ Investigating specific search term issues
- ✅ Validating treatment improvements
- **Output:** Hundreds/thousands of rows (one per search query)
- **Date Range:** May 30 - June 17, 2026 (fixed)

### Use **Query Classification Breakdown** When:
- ✅ Understanding performance by query type
- ✅ Analyzing restaurant vs item vs cuisine queries
- ✅ Finding which classifications perform best
- **Output:** Rows grouped by vertical, tier, and classification
- **Date Range:** May 30 - June 17, 2026 (fixed)

### Use **Exact Match Analysis** When:
- ✅ Understanding exact match positioning impact
- ✅ Analyzing order attribution by vendor
- ✅ Measuring displacement effects
- ✅ Restaurant query-specific analysis
- **Output:** Performance by exact match category (rank_1, displaced, no_match)
- **Date Range:** May 30 - June 17, 2026 (fixed)

### Recommended Workflow

**AB Test Analysis:**
1. **Start with Overall AB Test** → Is Treatment winning? (e.g., "+8% CTR, significant")
2. **Check traffic split** → Is it ~50/50? (e.g., "50.2% treatment traffic")
3. **Run Head/Torso/Tail AB Test** → Which tier wins? (e.g., "Head +12%, Torso +5%")
4. **Use Detailed AB Test** → Which queries win/lose? (e.g., "Top 10 wins, Top 10 losses")
5. **Run Query Classification** → Which query types perform best?
6. **Run Exact Match Analysis** → How does exact match positioning affect conversion?
7. **Validate before shipping** → Ensure consistent improvements across tiers

---

## 🚀 Quick Start

### Running AB Test Analysis

**Step 1: Open the AB Test Overall Query**
```bash
open ~/woowa_search_analysis/overall_comparison_query_ab_test.sql
```

**Step 2: Verify Date Range (Lines 6-7)**
```sql
DECLARE start_date DATE DEFAULT '2026-05-30';  -- AB test start date
DECLARE end_date DATE DEFAULT '2026-06-17';    -- AB test end date (inclusive)
```

**Step 3: Run in BigQuery**
- You'll get 2-3 rows (ALL, BAEMIN_DELIVERY only)
- Check `treatment_traffic_pct` (should be ~50%)
- Analysis covers full AB test period (May 30 - June 17, 2026)

**Date Range:**
All AB test queries use the same fixed date range for consistency:
- **Start:** May 30, 2026 (AB test launch)
- **End:** June 17, 2026 (inclusive)

**📖 For more AB test details:** See `AB_TEST_QUICK_START.md`

---

## 📊 What You'll Get

### Search Verticals Analyzed:
- ✅ **ALL** - Mixed Results Tab
- ✅ **BAEMIN_DELIVERY** - Delivery Tab
- ❌ **NULL_VERTICAL** - Excluded (browsing/favorites, not search)
- ❌ **BAEMIN_TAKEOUT** - Excluded (not in AB test scope)

### Metrics Provided:
- **Volume**: Searches, sessions, unique queries
- **Funnel**: CTR, CVR, ZRR
- **Quality**: Avg results, zero results
- **Engagement**: Pagination, click rank
- **Session**: Searches per session
- **Comparison**: % change, statistical significance
- **Traffic Split**: Validation of ~50/50 distribution

---

## 🎯 Key Metrics to Watch

| Metric | Good Value | Red Flag |
|--------|------------|----------|
| CTR | >10% (>0.1000) | <5% |
| CVR | 3-8% (0.03-0.08) | <1% |
| ZRR | <5% | >10% |
| Avg Click Rank | <3.0 | >5.0 |
| Clicks Position 1-3 | >60% | <40% |
| Traffic Split | 48-52% | <45% or >55% |

---

## 📈 Example Output

### Overall AB Test Query

| search_vertical | control_searches | control_cvr | treatment_searches | treatment_cvr | cvr_pct_change | cvr_stat_sig | treatment_traffic_pct |
|-----------------|------------------|-------------|--------------------|--------------:|---------------:|--------------|----------------------:|
| ALL | 1,250,000 | 0.0450 | 1,280,000 | 0.0485 | **+7.78%** | ✅ Yes | 50.6% |
| BAEMIN_DELIVERY | 980,000 | 0.0420 | 1,000,000 | 0.0455 | **+8.33%** | ✅ Yes | 50.5% |

**Interpretation:**
- ✅ Treatment is winning (+7.78% CVR overall)
- ✅ Statistically significant improvement
- ✅ Traffic split is balanced (~50/50)

---

## 📝 Tips for Analysis

1. **Start with Overall** - Get the high-level picture first
2. **Check Traffic Split** - Ensure ~50/50 distribution (validate AB test integrity)
3. **Drill Down by Tier** - Understand which tiers drive the win/loss
4. **Check Statistical Significance** - Don't act on small samples
5. **Analyze by Classification** - See if certain query types perform better
6. **Run Exact Match Analysis** - Understand positioning impact for restaurant queries
7. **Export to Sheets** - Use conditional formatting for quick insights

---

## 📅 Last Updated
June 24, 2026

## 🏷️ Version
v3.2 - Removed platform comparison queries, AB test focus only
- ✅ Fixed date range (May 30 - June 17, 2026) across all AB test queries
- ✅ AB Test: Control vs Treatment comparison
- ✅ Exact Match Analysis queries and guide
- ✅ Unified tier calculation across variations
- ✅ Traffic split validation
- ✅ Removed platform comparison (Woowa vs Global Search) queries

## 🔗 Related Resources

**Assignment Table Script:**
`/Users/k.musina/Desktop/analytics/gs_woowa_eppo_assignments.sql`

**Workflow Documentation:**
`/Users/aybueke.kayaci/dh-pm-claude-skills/workflows/woowa-ab-test-analysis.md`

**Assignment Table:** 
`dhub-gd-analytics.eppo_input.gs_woowa_assignments`

**Perseus Events Table:**
`fulfillment-dwh-production.curated_data_shared_data_stream_perseus.baemin_korea_perseus`

**Backend Tracking Table:**
`search-restaurant-stats-9826.backendtracking.vendor-v1`
