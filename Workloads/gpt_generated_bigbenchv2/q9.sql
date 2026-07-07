WITH sales AS (
    SELECT
        ws.ws_customer_id,
        ws.ws_item_id,
        ws.ws_quantity,
        i.i_price,
        i.i_category,
        i.i_category_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    s.i_category,
    SUM(s.ws_quantity) AS total_quantity,
    SUM(s.ws_quantity * s.i_price) AS total_revenue,
    AVG(s.i_price) AS avg_item_price
FROM sales s
JOIN customers c ON s.ws_customer_id = c.c_customer_id
GROUP BY c.c_customer_id, c.c_name, s.i_category
ORDER BY total_revenue DESC
LIMIT 10
