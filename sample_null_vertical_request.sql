-- Sample request with NULL search_vertical from today
-- Check if they have search queries

SELECT
  DATE(eventTimestamp) AS event_date,
  globalEntityId AS global_entity_id,
  sessionId AS session_id,
  JSON_VALUE(eventVariablesJson, '$.searchTrackingId') AS search_tracking_id,
  JSON_VALUE(eventVariablesJson, '$.searchRequestId') AS search_request_id,
  JSON_VALUE(eventVariablesJson, '$.searchTerm') AS search_term,
  JSON_VALUE(eventVariablesJson, '$.searchVerticalName') AS search_vertical_name,
  eventAction,
  eventOrigin,
  screenType,
  screenName,
  JSON_VALUE(eventVariablesJson, '$.shopQuantityTotal') AS shop_quantity_total,
  JSON_VALUE(eventVariablesJson, '$.shopListType') AS shop_list_type,
  JSON_VALUE(eventVariablesJson, '$.shopListTrigger') AS shop_list_trigger,
  eventVariablesJson AS full_json
FROM `fulfillment-dwh-production.curated_data_shared_data_stream_perseus.baemin_korea_perseus`
WHERE
  DATE(eventTimestamp) = CURRENT_DATE()
  AND eventAction = 'shop_list.updated'  -- Search result shown
  AND JSON_VALUE(eventVariablesJson, '$.searchVerticalName') IS NULL  -- NULL vertical
  AND JSON_VALUE(eventVariablesJson, '$.searchTrackingId') IS NOT NULL  -- Has tracking ID
ORDER BY eventTimestamp DESC
LIMIT 10;
