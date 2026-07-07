WITH parsed_logs AS (
    SELECT
        wl_id,
        wl_customer_id,
        wl_item_id,
        wl_webpage_name,
        CAST(wl_timestamp AS timestamp) AS ts,
        wl_key1,
        wl_key2,
        wl_key3
    FROM web_logs
    WHERE wl_webpage_name IS NOT NULL
)
SELECT
    DATE(ts) AS log_date,
    wl_webpage_name,
    COUNT(*) AS page_views,
    COUNT(DISTINCT wl_customer_id) AS unique_customers,
    SUM(wl_key1) AS total_key1,
    AVG(wl_key2) AS avg_key2
FROM parsed_logs
GROUP BY
    DATE(ts),
    wl_webpage_name
ORDER BY
    log_date DESC,
    page_views DESC
LIMIT 100
