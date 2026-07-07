WITH parsed_logs AS (
    SELECT
        wl_id,
        wl_customer_id,
        wl_item_id,
        wl_webpage_name,
        date_parse(wl_timestamp, '%Y-%m-%d %H:%i:%s') AS ts
    FROM web_logs
    WHERE wl_timestamp IS NOT NULL
)
SELECT
    wl_webpage_name,
    date_trunc('day', ts) AS log_date,
    COUNT(*) AS page_views,
    COUNT(DISTINCT wl_customer_id) AS unique_customers
FROM parsed_logs
WHERE ts >= date_add('day', -30, current_timestamp)
GROUP BY wl_webpage_name, date_trunc('day', ts)
ORDER BY page_views DESC
LIMIT 100
