WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        ws.ws_item_id,
        ws.ws_quantity,
        ws.ws_transaction_id
    FROM web_sales ws
    JOIN customers c
        ON ws.ws_customer_id = c.c_customer_id
)
SELECT
    c_customer_id,
    c_name,
    COUNT(DISTINCT ws_transaction_id) AS transaction_count,
    SUM(ws_quantity) AS total_quantity,
    AVG(ws_quantity) AS avg_quantity_per_transaction
FROM customer_sales
GROUP BY c_customer_id, c_name
ORDER BY total_quantity DESC
LIMIT 10
