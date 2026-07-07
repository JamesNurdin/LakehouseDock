WITH customer_sales AS (
    SELECT
        ws.ws_customer_id AS c_customer_id,
        COUNT(DISTINCT ws.ws_transaction_id) AS transaction_count,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_item_id) AS distinct_items
    FROM web_sales ws
    GROUP BY ws.ws_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    cs.transaction_count,
    cs.total_quantity,
    cs.distinct_items,
    cs.total_quantity / cs.transaction_count AS avg_quantity_per_tx
FROM customers c
JOIN customer_sales cs
    ON c.c_customer_id = cs.c_customer_id
ORDER BY avg_quantity_per_tx DESC
LIMIT 10
