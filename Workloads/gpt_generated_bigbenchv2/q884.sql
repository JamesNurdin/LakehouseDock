WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        ws.ws_quantity,
        ws.ws_item_id
    FROM customers c
    JOIN web_sales ws
        ON ws.ws_customer_id = c.c_customer_id
)
SELECT
    cs.c_customer_id,
    cs.c_name,
    SUM(cs.ws_quantity) AS total_quantity,
    COUNT(DISTINCT cs.ws_item_id) AS distinct_items
FROM customer_sales cs
GROUP BY cs.c_customer_id, cs.c_name
ORDER BY total_quantity DESC
LIMIT 10
