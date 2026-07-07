WITH agg AS (
    SELECT
        wl_customer_id,
        wl_webpage_name,
        COUNT(*) AS total_views,
        COUNT(DISTINCT wl_item_id) AS distinct_items,
        MAX(CAST(wl_timestamp AS timestamp)) AS latest_ts
    FROM web_logs
    GROUP BY wl_customer_id, wl_webpage_name
)
SELECT
    w.wl_id,
    w.wl_customer_id,
    w.wl_item_id,
    w.wl_webpage_name,
    w.wl_timestamp,
    agg.total_views,
    agg.distinct_items
FROM web_logs w
JOIN agg
    ON w.wl_customer_id = agg.wl_customer_id
    AND w.wl_webpage_name = agg.wl_webpage_name
    AND CAST(w.wl_timestamp AS timestamp) = agg.latest_ts
ORDER BY agg.total_views DESC
LIMIT 100
