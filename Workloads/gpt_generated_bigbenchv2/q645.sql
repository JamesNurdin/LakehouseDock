WITH customer_aggregates AS (
    SELECT
        wl_customer_id,
        COUNT(*) AS total_page_views,
        COUNT(DISTINCT wl_webpage_name) AS distinct_pages
    FROM web_logs
    GROUP BY wl_customer_id
)
SELECT
    w.wl_id,
    w.wl_customer_id,
    w.wl_webpage_name,
    w.wl_timestamp,
    ca.total_page_views,
    ca.distinct_pages
FROM web_logs AS w
JOIN customer_aggregates AS ca
    ON w.wl_customer_id = ca.wl_customer_id
ORDER BY w.wl_customer_id, w.wl_timestamp
LIMIT 100
