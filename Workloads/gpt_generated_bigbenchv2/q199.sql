WITH parsed_logs AS (
    SELECT
        wl_id,
        wl_customer_id,
        wl_item_id,
        wl_webpage_name,
        CAST(wl_timestamp AS timestamp) AS ts,
        wl_key1,
        wl_key2
    FROM web_logs
)
SELECT
    date_trunc('day', ts) AS log_date,
    wl_webpage_name,
    COUNT(*) AS visit_count,
    COUNT(DISTINCT wl_customer_id) AS unique_customers,
    COUNT(DISTINCT wl_item_id) AS distinct_items,
    AVG(wl_key1) AS avg_key1,
    AVG(wl_key2) AS avg_key2
FROM parsed_logs
GROUP BY date_trunc('day', ts), wl_webpage_name
ORDER BY log_date DESC, visit_count DESC
LIMIT 100
