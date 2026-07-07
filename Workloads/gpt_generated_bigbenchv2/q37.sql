WITH customer_agg AS (
    SELECT
        wl_customer_id,
        COUNT(*) AS log_count,
        MIN(wl_timestamp) AS first_timestamp,
        MAX(wl_timestamp) AS last_timestamp,
        SUM(wl_key1) AS total_key1,
        AVG(wl_key1) AS avg_key1
    FROM web_logs
    WHERE wl_timestamp >= '2023-01-01' AND wl_timestamp < '2024-01-01'
    GROUP BY wl_customer_id
)
SELECT
    wl.wl_id,
    wl.wl_customer_id,
    wl.wl_item_id,
    wl.wl_webpage_name,
    wl.wl_timestamp,
    ca.log_count,
    ca.first_timestamp,
    ca.last_timestamp,
    ca.total_key1,
    ca.avg_key1
FROM web_logs wl
JOIN customer_agg ca
    ON wl.wl_customer_id = ca.wl_customer_id
WHERE wl.wl_timestamp = ca.last_timestamp
ORDER BY ca.log_count DESC
LIMIT 10
