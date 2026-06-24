# Exact Match Analysis Guide

## Overview

This analysis examines how exact match positioning affects search performance and order attribution for restaurant-classified queries in the Woowa search A/B test.

**Date Range:** May 30 - June 17, 2026 (inclusive)  
**Variation:** B  
**Query Classification:** RESTAURANT  
**Attribution Model:** Last-click attribution

## Query Files

- **SQL Queries:** `exact_match_analysis_queries.sql`
- Contains 2 main queries for exact match analysis

## Key Concepts

### Exact Match Categories

1. **rank_1**: Exact match vendor appears at position 1 in search results
2. **displaced**: Exact match vendor is returned but NOT at position 1
3. **no_match**: No exact match vendor in the results

### Vendor Matching

- **Backend Tracking:** Uses `vendor.id` field from exact match vendors
- **Perseus (Clicks):** Uses `shopId` field from click events
- These fields must match to determine if an order came from the exact match vendor

## Query 1: Performance by Exact Match Category

### Purpose
Analyze searches, orders, and CVR by exact match positioning.

### Output Columns
- `exact_match_category`: rank_1, displaced, or no_match
- `searches`: Total search count
- `orders`: Total orders (last-click attributed)
- `cvr_pct`: Conversion rate percentage

### Sample Results

```csv
exact_match_category,searches,orders,cvr_pct
rank_1,2876326,655696,22.8
displaced,250492,15820,6.32
no_match,548251,34278,6.25
```

### Key Findings

- **Exact match at rank 1** drives **22.8% CVR** - 3.6x higher than displaced (6.32%)
- **Displaced vs No Match** perform similarly (6.32% vs 6.25%)
- **79% of restaurant queries** get exact match at rank 1 (2.88M out of 3.68M)
- **Only 7% are displaced** - relatively rare

**Insight:** Exact match needs to be at rank 1 to deliver value. When displaced, CVR drops to the same level as queries with no exact match.

## Query 2: Order Source Analysis

### Purpose
For queries with exact match (rank_1 and displaced), determine whether orders came from the exact match vendor or other vendors.

### Output Columns
- `exact_match_category`: rank_1 or displaced
- `searches`: Total search count
- `total_orders`: Total orders
- `orders_from_exact_match`: Orders from exact match vendor
- `orders_from_other_vendors`: Orders from non-exact-match vendors
- `overall_cvr_pct`: Overall CVR
- `exact_match_cvr_pct`: CVR from exact match vendor only
- `other_vendor_cvr_pct`: CVR from other vendors only
- `pct_orders_from_exact_match`: % of total orders from exact match vendor

### Sample Results

```csv
exact_match_category,searches,total_orders,orders_from_exact_match,orders_from_other_vendors,overall_cvr_pct,exact_match_cvr_pct,other_vendor_cvr_pct,pct_orders_from_exact_match
rank_1,2876326,655696,623569,32127,22.8,21.68,1.12,95.1
displaced,250492,15820,7636,8184,6.32,3.05,3.27,48.27
```

### Key Findings

#### When Exact Match is at Rank 1:
- **95.1% of orders** come from the exact match vendor (623k out of 655k)
- Exact match vendor drives **21.68% CVR**
- Other vendors only drive **1.12% CVR**
- **Conclusion:** Exact match at rank 1 captures nearly all conversions

#### When Exact Match is Displaced:
- Only **48.27% of orders** come from the exact match vendor (7.6k out of 15.8k)
- Exact match vendor drives **3.05% CVR** - much lower than when at rank 1
- Other vendors drive **3.27% CVR** - similar to displaced exact match
- Users split almost 50/50 between exact match and other options
- **Conclusion:** Displacement causes an **86% drop in CVR** for the exact match vendor (21.68% → 3.05%)

## Technical Notes

### Assignment Table
Uses `dhub-gd-analytics.eppo_input.gs_woowa_assignments` which includes:
- Exposure gate (users who searched after assignment)
- App version filters
- Experiment date filtering

### Backend Tracking
- Table: `search-restaurant-stats-9826.backendtracking.vendor-v1`
- Classification field: `ranking.request.query_classification` (must be "RESTAURANT" uppercase)
- Exact match flag: `vendor.is_exact_match = TRUE`
- Rank field: `vendor.final_rank`

### Perseus Event Data
- Table: `fulfillment-dwh-production.curated_data_shared_data_stream_perseus.baemin_korea_perseus`
- Search events: `eventAction = "shop_list.updated"`
- Click events: `eventAction = "shop.clicked"`
- Transaction events: `eventAction = "transaction"`
- Vendor ID field: `shopId` (NOT shopBizesCode or vendorId)

### Attribution Logic
**Last-Click Attribution:**
1. Find all clicks within a session before a transaction
2. Select the click with the latest timestamp before the transaction
3. Attribute the order to that click's search_request_id
4. Match the clicked vendor (shopId) with exact match vendors (vendor.id)

## Usage Example

```bash
# Run Query 1 - Performance by Category
bq query --use_legacy_sql=false < exact_match_analysis_queries.sql

# Extract just Query 1
sed -n '/QUERY 1:/,/QUERY 2:/p' exact_match_analysis_queries.sql | \
  sed '$d' | \
  bq query --use_legacy_sql=false

# Extract just Query 2
sed -n '/QUERY 2:/,$p' exact_match_analysis_queries.sql | \
  bq query --use_legacy_sql=false
```

## Recommendations

Based on the analysis:

1. **Prioritize Exact Match at Rank 1:** The data strongly validates that exact match positioning at rank 1 is critical for conversion performance.

2. **Investigate Displacement Cases:** Only 7% of queries have displaced exact matches, but these lose 86% of their conversion power. Understanding what causes displacement could help improve overall performance.

3. **Consider Algorithm Changes:** When exact match is displaced, users show no preference between exact match and other vendors (both ~3% CVR, split 50/50). This suggests the ranking algorithm may be positioning other strong candidates at rank 1.

4. **Monitor No-Match Queries:** 15% of restaurant queries (548k) have no exact match at all. These maintain ~6% CVR through other vendors, suggesting search is still functional without exact match, but at significantly lower conversion rates.

## Common Issues

### Zero Orders from Exact Match
**Symptom:** `orders_from_exact_match = 0` in Query 2 results

**Cause:** Vendor ID mismatch between backend tracking and Perseus

**Solution:** Ensure you're using:
- `vendor.id` from backend tracking exact match vendors
- `shopId` from Perseus click events (NOT shopBizesCode or vendorId)

### Empty Results
**Symptom:** No rows returned

**Cause:** Query classification mismatch

**Solution:** Use uppercase "RESTAURANT" not lowercase "restaurant":
```sql
WHERE ranking.request.query_classification = "RESTAURANT"
```

### Date Range Issues
**Symptom:** Results don't match expected time period

**Solution:** Verify both tables use correct date filtering:
```sql
-- Assignment table
WHERE DATE(assignment_timestamp) BETWEEN "2026-05-30" AND "2026-06-17"

-- Backend tracking
WHERE DATE(timestamp_utc) BETWEEN "2026-05-30" AND "2026-06-17"

-- Perseus
WHERE DATE(eventTimestamp) BETWEEN "2026-05-30" AND "2026-06-17"
```

## Related Documentation

- [AB Test Quick Start](AB_TEST_QUICK_START.md)
- [Query Classification Guide](QUERY_CLASSIFICATION_GUIDE.md)
- [AB Test Analyst Guide](AB_TEST_ANALYST_GUIDE.md)
- [Comprehensive Query Guide](comprehensive_query_dimensions_guide.md)
