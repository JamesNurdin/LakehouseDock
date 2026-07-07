WITH page_stats AS (
    SELECT
        wl_webpage_name,
        COUNT(*) AS visit_count,
        COUNT(DISTINCT wl_customer_id) AS distinct_customers,
        AVG(wl_key1) AS avg_key1
    FROM web_logs
    GROUP BY wl_webpage_name
)
SELECT
    ps.wl_webpage_name,
    ps.visit_count,
    ps.distinct_customers,
    ps.avg_key1,
    wl.wl_id,
    wl.wl_timestamp
FROM page_stats AS ps
JOIN web_logs AS wl
    ON wl.wl_webpage_name = ps.wl_webpage_name
WHERE ps.visit_count = (
    SELECT MAX(visit_count) FROM page_stats
)
ORDER BY wl.wl_timestamp DESC
LIMIT 10
