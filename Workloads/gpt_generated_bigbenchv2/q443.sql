WITH daily_page_stats AS (
    SELECT
        date(cast(wl_timestamp AS timestamp)) AS log_date,
        wl_webpage_name,
        count(*) AS visit_count,
        count(DISTINCT wl_customer_id) AS unique_customers,
        sum(wl_key1) AS total_key1
    FROM web_logs
    WHERE wl_timestamp IS NOT NULL
    GROUP BY date(cast(wl_timestamp AS timestamp)), wl_webpage_name
)
SELECT
    log_date,
    wl_webpage_name,
    visit_count,
    unique_customers,
    total_key1
FROM daily_page_stats
ORDER BY log_date DESC, visit_count DESC
LIMIT 100
