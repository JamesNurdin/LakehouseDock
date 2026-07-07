WITH min_max AS (
  SELECT wl_customer_id,
         wl_item_id,
         MIN(wl_timestamp) AS min_ts,
         MAX(wl_timestamp) AS max_ts
  FROM web_logs
  GROUP BY wl_customer_id, wl_item_id
)
SELECT w.wl_customer_id,
       w.wl_item_id,
       date_diff('second', CAST(m.min_ts AS timestamp), CAST(m.max_ts AS timestamp)) AS total_seconds,
       COUNT(*) AS view_count
FROM web_logs w
JOIN min_max m
  ON w.wl_customer_id = m.wl_customer_id
 AND w.wl_item_id = m.wl_item_id
GROUP BY w.wl_customer_id, w.wl_item_id, m.min_ts, m.max_ts
ORDER BY total_seconds DESC
LIMIT 10
