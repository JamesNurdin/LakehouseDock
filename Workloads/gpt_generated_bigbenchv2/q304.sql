WITH sales AS (
    SELECT
        ws.ws_transaction_id,
        ws.ws_customer_id,
        ws.ws_item_id,
        ws.ws_quantity,
        i.i_category_name,
        i.i_class_id,
        i.i_price,
        i.i_comp_price
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
)
SELECT
    i_category_name,
    i_class_id,
    SUM(ws_quantity * i_price) AS total_revenue,
    SUM(ws_quantity * i_comp_price) AS total_comp_revenue,
    SUM(ws_quantity) AS total_quantity_sold,
    COUNT(DISTINCT ws_customer_id) AS distinct_customers,
    AVG(i_price) AS average_price
FROM sales
GROUP BY i_category_name, i_class_id
HAVING SUM(ws_quantity * i_price) > 10000
ORDER BY total_revenue DESC
LIMIT 10
