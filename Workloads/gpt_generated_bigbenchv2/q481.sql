WITH parsed_logs AS (
    SELECT
        wl_id,
        wl_customer_id,
        wl_item_id,
        wl_webpage_name,
        CAST(wl_timestamp AS timestamp) AS wl_ts,
        DATE(CAST(wl_timestamp AS timestamp)) AS visit_date
    FROM web_logs
    WHERE wl_timestamp IS NOT NULL
)
SELECT
    wl_webpage_name,
    visit_date,
    COUNT(*) AS total_visits,
    COUNT(DISTINCT wl_customer_id) AS unique_customers
FROM parsed_logs
GROUP BY wl_webpage_name, visit_date
ORDER BY total_visits DESC
LIMIT 20
