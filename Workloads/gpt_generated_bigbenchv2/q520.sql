SELECT
  date(cast(wl_timestamp AS timestamp)) AS log_date,
  COUNT(*) AS total_events,
  COUNT(DISTINCT wl_customer_id) AS unique_customers,
  COUNT(DISTINCT wl_item_id) AS unique_items,
  COUNT(DISTINCT wl_webpage_name) AS unique_pages
FROM web_logs
WHERE wl_timestamp IS NOT NULL
  AND date(cast(wl_timestamp AS timestamp)) >= current_date - interval '30' day
GROUP BY date(cast(wl_timestamp AS timestamp))
ORDER BY log_date DESC
LIMIT 30
