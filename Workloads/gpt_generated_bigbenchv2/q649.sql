WITH customer_earliest_latest AS (
    SELECT wl_customer_id,
           min(CAST(wl_timestamp AS timestamp)) AS earliest_ts,
           max(CAST(wl_timestamp AS timestamp)) AS latest_ts
    FROM web_logs
    GROUP BY wl_customer_id
)
SELECT w.wl_customer_id,
       COUNT(DISTINCT w.wl_item_id) AS distinct_items_viewed,
       c.earliest_ts,
       c.latest_ts
FROM web_logs w
JOIN customer_earliest_latest c
  ON w.wl_customer_id = c.wl_customer_id
GROUP BY w.wl_customer_id, c.earliest_ts, c.latest_ts
ORDER BY distinct_items_viewed DESC
LIMIT 100
