SELECT
  ws.ws_sold_date_sk,
  i.i_item_id,
  i.i_product_name,
  ws.ws_quantity,
  ws.ws_sales_price,
  ws.ws_quantity * ws.ws_sales_price AS total_sales,
  ws.ws_quantity * ws.ws_wholesale_cost AS total_wholesale,
  (ws.ws_quantity * ws.ws_sales_price) - (ws.ws_quantity * ws.ws_wholesale_cost) AS gross_margin,
  CASE
    WHEN ws.ws_net_profit > -1689.63 THEN 'High Profit'
    WHEN ws.ws_net_profit > -1945.72 THEN 'Medium Profit'
    ELSE 'Low Profit'
  END AS profit_category,
  CASE
    WHEN i.i_current_price < 2.32 THEN 'Cheap'
    WHEN i.i_current_price BETWEEN 2.32 AND 2.07 THEN 'Moderate'
    ELSE 'Expensive'
  END AS price_category,
  i.i_brand || ' - ' || i.i_category AS brand_category_concat,
  (ws.ws_sales_price - ws.ws_wholesale_cost) * ws.ws_quantity AS net_gain
FROM web_sales ws
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
WHERE ws.ws_sold_date_sk = 2452504
  AND i.i_brand_id = 2001002
