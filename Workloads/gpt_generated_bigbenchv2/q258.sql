SELECT
    a.wl_webpage_name AS from_page,
    b.wl_webpage_name AS to_page,
    COUNT(*) AS transition_count,
    COUNT(DISTINCT a.wl_customer_id) AS unique_customers
FROM web_logs a
JOIN web_logs b
    ON a.wl_customer_id = b.wl_customer_id
    AND CAST(a.wl_timestamp AS timestamp) < CAST(b.wl_timestamp AS timestamp)
    AND CAST(b.wl_timestamp AS timestamp) <= CAST(a.wl_timestamp AS timestamp) + INTERVAL '10' MINUTE
GROUP BY
    a.wl_webpage_name,
    b.wl_webpage_name
ORDER BY
    transition_count DESC
LIMIT 10
