WITH combined_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        ss.ss_quantity AS quantity,
        ss.ss_ts AS ts,
        'store' AS channel
    FROM store_sales ss
    INNER JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    UNION ALL
    SELECT
        c.c_customer_id,
        c.c_name,
        ws.ws_quantity AS quantity,
        ws.ws_ts AS ts,
        'web' AS channel
    FROM web_sales ws
    INNER JOIN customers c ON ws.ws_customer_id = c.c_customer_id
)
SELECT
    c_customer_id,
    c_name,
    SUM(quantity) AS total_quantity,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN channel = 'store' THEN quantity ELSE 0 END) AS store_quantity,
    SUM(CASE WHEN channel = 'web' THEN quantity ELSE 0 END) AS web_quantity,
    COUNT(CASE WHEN channel = 'store' THEN 1 END) AS store_transactions,
    COUNT(CASE WHEN channel = 'web' THEN 1 END) AS web_transactions
FROM combined_sales
WHERE CAST(ts AS timestamp) >= TIMESTAMP '2023-01-01 00:00:00'
  AND CAST(ts AS timestamp) < TIMESTAMP '2024-01-01 00:00:00'
GROUP BY c_customer_id, c_name
ORDER BY total_quantity DESC
LIMIT 10
