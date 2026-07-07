WITH parsed_logs AS (
    SELECT
        wl_id,
        wl_customer_id,
        wl_item_id,
        wl_webpage_name,
        CAST(wl_timestamp AS timestamp) AS ts,
        DATE(CAST(wl_timestamp AS timestamp)) AS event_date,
        wl_key1,
        wl_key2,
        wl_key3
    FROM web_logs
    WHERE wl_timestamp IS NOT NULL
)
SELECT
    wl_webpage_name,
    event_date,
    COUNT(*) AS total_events,
    COUNT(DISTINCT wl_customer_id) AS unique_customers,
    COUNT(DISTINCT wl_item_id) AS unique_items,
    APPROX_PERCENTILE(wl_key1, 0.5) AS median_key1
FROM parsed_logs
GROUP BY wl_webpage_name, event_date
ORDER BY total_events DESC
LIMIT 50
