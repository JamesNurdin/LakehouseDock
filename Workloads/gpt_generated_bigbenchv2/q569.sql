WITH per_customer AS (
    SELECT
        wl_customer_id,
        COUNT(*) AS page_view_count,
        COUNT(DISTINCT wl_item_id) AS distinct_items_viewed,
        MAX(wl_timestamp) AS latest_timestamp
    FROM web_logs
    GROUP BY wl_customer_id
)
SELECT
    pc.wl_customer_id,
    pc.page_view_count,
    pc.distinct_items_viewed,
    pc.latest_timestamp,
    wl.wl_webpage_name,
    wl.wl_item_id
FROM per_customer pc
JOIN web_logs wl
  ON wl.wl_customer_id = pc.wl_customer_id
 AND wl.wl_timestamp = pc.latest_timestamp
ORDER BY pc.page_view_count DESC
LIMIT 100
