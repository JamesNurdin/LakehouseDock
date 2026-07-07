WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        SUM(ws.ws_quantity * i.i_price) AS total_sales
    FROM web_sales ws
    JOIN customers c
        ON ws.ws_customer_id = c.c_customer_id
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY c.c_customer_id, c.c_name
)
SELECT
    c_customer_id,
    c_name,
    total_sales
FROM customer_sales
ORDER BY total_sales DESC
LIMIT 10
