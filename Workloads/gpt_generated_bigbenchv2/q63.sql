WITH sales AS (
    SELECT
        ws.ws_customer_id,
        ws.ws_item_id,
        ws.ws_quantity,
        c.c_name,
        i.i_category,
        i.i_price
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    s.c_name,
    s.i_category,
    SUM(s.ws_quantity) AS total_quantity,
    SUM(s.ws_quantity * s.i_price) AS total_revenue
FROM sales s
GROUP BY
    s.c_name,
    s.i_category
ORDER BY total_revenue DESC
LIMIT 100
