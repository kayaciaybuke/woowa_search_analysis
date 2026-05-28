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
