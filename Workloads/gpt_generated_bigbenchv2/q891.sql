WITH recent_logs AS (
    SELECT
        wl_customer_id,
        wl_webpage_name,
        cast(wl_timestamp AS timestamp) AS ts
    FROM web_logs
    WHERE cast(wl_timestamp AS timestamp) >= current_timestamp - INTERVAL '30' DAY
)
SELECT
    wl_webpage_name,
    DATE(ts) AS visit_date,
    COUNT(*) AS total_visits,
    COUNT(DISTINCT wl_customer_id) AS unique_customers
FROM recent_logs
GROUP BY wl_webpage_name, DATE(ts)
ORDER BY total_visits DESC
LIMIT 100
