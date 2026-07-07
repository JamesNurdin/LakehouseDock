SELECT
    c.c_customer_id,
    c.c_name,
    i.i_category_id,
    i.i_category,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_quantity * i.i_price) AS total_sales_amount,
    AVG(i.i_price) AS avg_item_price
FROM web_sales ws
JOIN customers c ON ws.ws_customer_id = c.c_customer_id
JOIN items i ON ws.ws_item_id = i.i_item_id
GROUP BY
    c.c_customer_id,
    c.c_name,
    i.i_category_id,
    i.i_category
ORDER BY total_sales_amount DESC
LIMIT 10
