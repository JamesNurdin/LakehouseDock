WITH daily_page_stats AS (
    SELECT
        date(cast(wl_timestamp as timestamp)) AS log_date,
        wl_webpage_name,
        COUNT(*) AS log_count,
        COUNT(DISTINCT wl_customer_id) AS distinct_customers,
        AVG(wl_key1) AS avg_key1,
        SUM(wl_key2) AS sum_key2
    FROM web_logs
    WHERE wl_timestamp >= '2023-01-01' AND wl_timestamp < '2023-02-01'
    GROUP BY date(cast(wl_timestamp as timestamp)), wl_webpage_name
)
SELECT
    log_date,
    wl_webpage_name,
    log_count,
    distinct_customers,
    avg_key1,
    sum_key2
FROM daily_page_stats
ORDER BY log_date ASC, log_count DESC
LIMIT 100
