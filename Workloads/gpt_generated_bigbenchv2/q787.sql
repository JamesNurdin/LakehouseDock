WITH customer_events AS (
    SELECT wl_customer_id,
           COUNT(*) AS event_count,
           COUNT(DISTINCT wl_item_id) AS unique_items
    FROM web_logs
    GROUP BY wl_customer_id
)
SELECT ce.wl_customer_id,
       ce.event_count,
       ce.unique_items,
       MIN(wl.wl_timestamp) AS first_event_timestamp,
       MAX(wl.wl_timestamp) AS last_event_timestamp
FROM customer_events ce
JOIN web_logs wl
  ON ce.wl_customer_id = wl.wl_customer_id
GROUP BY ce.wl_customer_id, ce.event_count, ce.unique_items
ORDER BY ce.event_count DESC
LIMIT 10
