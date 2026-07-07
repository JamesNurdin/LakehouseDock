WITH parsed_logs AS (
    SELECT
        wl_id,
        wl_customer_id,
        wl_item_id,
        wl_webpage_name,
        date_parse(wl_timestamp, '%Y-%m-%d %H:%i:%s') AS wl_ts,
        wl_key1
    FROM web_logs
)
SELECT
    wl_webpage_name,
    COUNT(*) AS total_logs,
    COUNT(DISTINCT wl_customer_id) AS unique_customers,
    COUNT(DISTINCT wl_item_id) AS unique_items,
    AVG(wl_key1) AS avg_key1,
    MAX(wl_ts) AS most_recent_ts
FROM parsed_logs
WHERE date(wl_ts) >= current_date - INTERVAL '30' DAY
GROUP BY wl_webpage_name
ORDER BY total_logs DESC
LIMIT 10
