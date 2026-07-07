SELECT
    i.i_category,
    i.i_category_id,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_quantity * i.i_price) AS total_sales,
    AVG(i.i_price) AS avg_price,
    COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers
FROM web_sales ws
JOIN items i
    ON ws.ws_item_id = i.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_sales DESC
LIMIT 10
