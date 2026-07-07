WITH page_stats AS (
    SELECT
        wl_webpage_name,
        COUNT(*) AS page_views,
        COUNT(DISTINCT wl_customer_id) AS unique_customers,
        AVG(wl_key1) AS avg_key1
    FROM web_logs
    GROUP BY wl_webpage_name
)
SELECT
    w.wl_id,
    w.wl_customer_id,
    w.wl_item_id,
    w.wl_webpage_name,
    w.wl_timestamp,
    w.wl_key1,
    p.page_views,
    p.unique_customers,
    p.avg_key1,
    w.wl_key1 - p.avg_key1 AS key1_deviation
FROM web_logs AS w
JOIN page_stats AS p
    ON w.wl_webpage_name = p.wl_webpage_name
WHERE w.wl_key1 > p.avg_key1
ORDER BY p.page_views DESC
LIMIT 100
