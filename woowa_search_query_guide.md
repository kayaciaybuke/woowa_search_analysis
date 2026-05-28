# Woowa Search Analysis Query Guide

**⚠️ Important: Query includes these filters:**
- ✅ Only shows results where **Global Search has ≥5 searches** (removes low-volume noise)
- ✅ Includes **NULL_VERTICAL** (old Woowa search with exceptionally high CVR ~75%!)
- ✅ Excludes **BAEMIN_TAKEOUT** (not served by Global Search)

## 1. First: Sample the Data

Run this query to understand what fields are available in your Perseus events:

```sql
-- Sample Perseus events to understand available fields
SELECT
  eventTimestamp,
  eventAction,
  eventOrigin,
  globalEntityId,
  sessionId,
  screenType,
  screenName,
  -- Extract all search-related fields from eventVariablesJson
  JSON_VALUE(eventVariablesJson, '$.searchTrackingId') AS search_tracking_id,
  JSON_VALUE(eventVariablesJson, '$.searchRequestId') AS search_request_id,
  JSON_VALUE(eventVariablesJson, '$.searchTerm') AS search_term,
  JSON_VALUE(eventVariablesJson, '$.searchVerticalName') AS search_vertical_name,
  JSON_VALUE(eventVariablesJson, '$.switchVerticalName') AS switch_vertical_name,
  JSON_VALUE(eventVariablesJson, '$.eventOrigin') AS event_origin_from_json,
  JSON_VALUE(eventVariablesJson, '$.shopListType') AS shop_list_type,
  JSON_VALUE(eventVariablesJson, '$.shopQuantityTotal') AS shop_quantity_total,
  JSON_VALUE(eventVariablesJson, '$.shopPosition') AS shop_position,
  JSON_VALUE(eventVariablesJson, '$.shopsIds') AS shops_ids,
  JSON_VALUE(eventVariablesJson, '$.shopListTrigger') AS shop_list_trigger,
  JSON_VALUE(eventVariablesJson, '$.shopId') AS shop_id,
  JSON_VALUE(eventVariablesJson, '$.shopType') AS shop_type,
  -- Full JSON for inspection
  eventVariablesJson
FROM `fulfillment-dwh-production.curated_data_shared_data_stream_perseus.baemin_korea_perseus`
WHERE 
  DATE(eventTimestamp) = CURRENT_DATE() - 1  -- Yesterday's data
  AND eventAction IN ('shop_list.updated', 'shop.clicked', 'transaction', 'search_bar.clicked', 'search_details.loaded')
LIMIT 20;
```

## 2. Key Fields You Should Consider

Based on the Woowa tracking requirements document, here are **important fields you might be missing**:

### Search Vertical Breakdown
- **`searchVerticalName`**: Distinguishes between:
  - `ALL` - Mixed Results Tab (all vendors)
  - `BAEMIN_DELIVERY` - Delivery Results Tab
  - `BAEMIN_TAKEOUT` - Pickup Results Tab
  - `HYPER_MARKET` - QC Results Tab
  - `COMMERCE` - eCommerce Results Tab

### Event Origin (How Search Was Initiated)
- **`eventOrigin`**: Shows user path:
  - `manual` - User typed search
  - `autocomplete` - Clicked autocomplete suggestion
  - `recent_search` - Clicked recent search
  - `popular_search` - Clicked popular keyword
  - `home_search` - Initiated from home screen
  - `search_results_mixed/delivery/pickup` - From results page
  - `restaurantMenu` - From restaurant details page

### Shop List Trigger (What Changed Results)
- **`shopListTrigger`**: Why results updated:
  - `search` - Initial search
  - `vertical_change` - User switched tabs (All → Delivery)
  - `filter_applied` - User applied filter
  - `filter_removed` - User removed filter

### Result Quality Metrics
- **`shopQuantityTotal`**: Number of results returned
- **`shopListType`**: Type of shops shown (restaurants, shops, mixed)
- **`shopsIds`**: Comma-separated vendor IDs in order
- **Zero Result Rate (ZRR)**: % of searches with 0 results

### User Engagement
- **`shop_list.expanded`**: Pagination (scrolled past first 50)
- **`shopPosition`**: Click rank (which position was clicked)
- **Average click rank**: Quality indicator

### Screen Context
- **`screenType`**: Where event occurred (home, SEARCH, shop_details, cart)
- **`screenName`**: Specific screen name

## 3. Comparison Query Features

The updated query now includes:

### ✅ Date Configuration (Easy to Change)
```sql
DECLARE start_date DATE DEFAULT CURRENT_DATE() - 1;  -- Yesterday
DECLARE end_date DATE DEFAULT CURRENT_DATE() - 1;    -- Yesterday
```

**To analyze multiple days:**
```sql
DECLARE start_date DATE DEFAULT CURRENT_DATE() - 7;  -- Last week
DECLARE end_date DATE DEFAULT CURRENT_DATE() - 1;    -- Until yesterday
```

### ✅ Search Vertical Breakdown
Results are now separated by:
- **ALL** tab searches (mixed results)
- **BAEMIN_DELIVERY** tab searches (delivery only)
- **NULL_VERTICAL** searches (old Woowa search with ~75% CVR!)
- **Note**: BAEMIN_TAKEOUT excluded (not served by Global Search)

### ✅ Additional Metrics
Now includes:
- **Zero Result Rate (ZRR)**: % searches with 0 results
- **Average Results**: Avg vendors shown
- **Pagination Rate**: % users scrolling past initial results

### ✅ Statistical Significance
- Uses z-test for proportions (95% confidence)
- Shows "Yes" if difference is statistically significant
- Shows "Insufficient Data" if sample size < 30

## 4. Output Format

| search_vertical | search_query | woowa_search_searches | woowa_search_ctr | woowa_search_cvr | global_search_searches | global_search_ctr | global_search_cvr | ctr_pct_change | cvr_pct_change | ctr_significant | cvr_significant |
|-----------------|--------------|---------------------|----------------|----------------|-------------------|---------------|---------------|----------------|----------------|----------------|----------------|
| ALL | birthday cake | 150 | 0.1200 | 0.0533 | 230 | 0.1478 | 0.0609 | +23.17% | +14.26% | Yes | No |
| BAEMIN_DELIVERY | pizza | 280 | 0.0950 | 0.0450 | 340 | 0.1100 | 0.0520 | +15.79% | +15.56% | Yes | Yes |
| NULL_VERTICAL | chicken | 320 | 0.6500 | 0.7496 | 85 | 0.6200 | 0.7200 | -4.62% | -3.95% | No | No |

## 5. Fields You Should Monitor But Might Be Missing

### Additional Dimensions Available for Future Analysis:
1. **`switchVerticalName`**: Track if users switched tabs (e.g., ALL → Delivery)
2. **`eventOrigin` breakdown**: Compare CTR by how search was initiated
3. **Time of day analysis**: Peak hours performance

**Note:** Pagination, click rank, filters, session metrics, and search term popularity are already included in the comprehensive query!

## 6. Quick Check: Are You Missing Data?

Run this diagnostic query:

```sql
SELECT
  'searchTrackingId' AS field_name,
  COUNTIF(JSON_VALUE(eventVariablesJson, '$.searchTrackingId') IS NOT NULL) AS populated,
  COUNTIF(JSON_VALUE(eventVariablesJson, '$.searchTrackingId') IS NULL) AS null_count
FROM `fulfillment-dwh-production.curated_data_shared_data_stream_perseus.baemin_korea_perseus`
WHERE DATE(eventTimestamp) = CURRENT_DATE() - 1
  AND eventAction = 'shop_list.updated'

UNION ALL

SELECT
  'searchVerticalName' AS field_name,
  COUNTIF(JSON_VALUE(eventVariablesJson, '$.searchVerticalName') IS NOT NULL) AS populated,
  COUNTIF(JSON_VALUE(eventVariablesJson, '$.searchVerticalName') IS NULL) AS null_count
FROM `fulfillment-dwh-production.curated_data_shared_data_stream_perseus.baemin_korea_perseus`
WHERE DATE(eventTimestamp) = CURRENT_DATE() - 1
  AND eventAction = 'shop_list.updated';
```

## 7. Next Steps

1. **Run the sampling query** to see actual data
2. **Check for null values** in key fields
3. **Run comparison query** with yesterday's data first
4. **Expand to weekly** once you validate results
5. **Add event_origin breakdown** if needed
6. **Monitor ZRR** (Zero Result Rate) - critical for search quality
