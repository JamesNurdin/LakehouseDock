WITH parsed_logs AS (
    SELECT
        wl_id,
        wl_customer_id,
        wl_item_id,
        wl_webpage_name,
        CAST(wl_timestamp AS timestamp) AS ts,
        wl_key1
    FROM web_logs
    WHERE CAST(wl_timestamp AS timestamp) >= TIMESTAMP '2023-01-01'
      AND CAST(wl_timestamp AS timestamp) < TIMESTAMP '2024-01-01'
)
SELECT
    wl_webpage_name,
    date_trunc('day', ts) AS log_date,
    COUNT(*) AS total_hits,
    COUNT(DISTINCT wl_customer_id) AS unique_customers,
    SUM(wl_key1) AS sum_key1
FROM parsed_logs
GROUP BY
    wl_webpage_name,
    date_trunc('day', ts)
ORDER BY
    log_date,
    total_hits DESC
