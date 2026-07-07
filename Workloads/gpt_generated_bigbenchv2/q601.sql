SELECT
    wl_webpage_name,
    date(CAST(wl_timestamp AS timestamp)) AS log_date,
    COUNT(*) AS page_views,
    COUNT(DISTINCT wl_customer_id) AS unique_customers,
    SUM(wl_key1) AS total_key1,
    AVG(wl_key2) AS avg_key2
FROM web_logs
WHERE wl_key1 IS NOT NULL
GROUP BY wl_webpage_name, date(CAST(wl_timestamp AS timestamp))
ORDER BY page_views DESC
LIMIT 100
