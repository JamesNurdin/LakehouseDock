SELECT ws.ws_item_sk,
       ws.ws_quantity,
       ws.ws_sales_price,
       ws.ws_quantity * ws.ws_sales_price AS revenue,
       CASE WHEN ws.ws_quantity > 10 THEN 'High Quantity' ELSE 'Low Quantity' END AS quantity_category,
       CASE WHEN ws.ws_net_profit > 1000 THEN 'Profitable' ELSE 'Not Profitable' END AS profit_status,
       (ws.ws_sales_price - ws.ws_wholesale_cost) * ws.ws_quantity AS gross_margin,
       w.w_warehouse_name,
       w.w_gmt_offset + 5.0 AS adjusted_gmt_offset,
       (ws.ws_sales_price * ws.ws_quantity) / (w.w_gmt_offset + 1) AS adjusted_revenue
FROM web_sales ws
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ws.ws_quantity > 82 AND w.w_gmt_offset < -6.00
