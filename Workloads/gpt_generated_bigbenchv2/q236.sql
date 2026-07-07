SELECT i.i_category AS category,
       SUM(ws.ws_quantity) AS total_quantity,
       SUM(ws.ws_quantity * i.i_price) AS total_revenue,
       COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers
FROM web_sales ws
JOIN items i ON ws.ws_item_id = i.i_item_id
GROUP BY i.i_category
ORDER BY total_revenue DESC
