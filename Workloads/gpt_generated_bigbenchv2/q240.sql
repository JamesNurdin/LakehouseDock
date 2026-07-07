WITH page_counts AS (
    SELECT
        wl_customer_id,
        wl_webpage_name,
        COUNT(*) AS log_count,
        SUM(wl_key1) AS sum_key1,
        SUM(wl_key2) AS sum_key2
    FROM web_logs
    GROUP BY wl_customer_id, wl_webpage_name
    HAVING COUNT(*) >= 100
)
SELECT
    wl_customer_id,
    wl_webpage_name,
    log_count,
    sum_key1,
    sum_key2
FROM page_counts
ORDER BY wl_customer_id, log_count DESC
LIMIT 50
