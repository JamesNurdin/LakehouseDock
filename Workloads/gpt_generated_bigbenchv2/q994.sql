WITH ws_details AS (
    SELECT
        ws.ws_customer_id,
        ws.ws_quantity,
        i.i_category,
        i.i_price,
        c.c_name
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    i_category,
    COUNT(DISTINCT ws_customer_id) AS distinct_customers,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_quantity * i_price) AS total_revenue
FROM ws_details
GROUP BY i_category
ORDER BY total_revenue DESC
LIMIT 10
