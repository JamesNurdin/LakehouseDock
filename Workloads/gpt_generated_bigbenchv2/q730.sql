WITH logs_jan2023 AS (
    SELECT
        wl_id,
        wl_customer_id,
        wl_item_id,
        wl_webpage_name,
        try_cast(wl_timestamp AS timestamp) AS wl_ts,
        wl_key1
    FROM web_logs
    WHERE try_cast(wl_timestamp AS timestamp) >= TIMESTAMP '2023-01-01 00:00:00'
      AND try_cast(wl_timestamp AS timestamp) < TIMESTAMP '2023-02-01 00:00:00'
)
SELECT
    wl_webpage_name,
    date_trunc('hour', wl_ts) AS hour_ts,
    COUNT(*) AS visit_count,
    COUNT(DISTINCT wl_customer_id) AS unique_customers,
    AVG(wl_key1) AS avg_key1
FROM logs_jan2023
GROUP BY wl_webpage_name, date_trunc('hour', wl_ts)
ORDER BY visit_count DESC
LIMIT 20
