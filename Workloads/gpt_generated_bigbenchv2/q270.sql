SELECT
    c.c_customer_id,
    c.c_name,
    COUNT(DISTINCT ws.ws_transaction_id) AS transaction_count,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(DISTINCT ws.ws_item_id) AS distinct_items,
    CAST(SUM(ws.ws_quantity) AS double) / COUNT(DISTINCT ws.ws_transaction_id) AS avg_quantity_per_transaction
FROM
    web_sales ws
JOIN
    customers c
    ON ws.ws_customer_id = c.c_customer_id
GROUP BY
    c.c_customer_id,
    c.c_name
ORDER BY
    total_quantity DESC
LIMIT 10
