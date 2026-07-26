SELECT i.i_category,
       COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
       SUM(ws.ws_ext_sales_price) AS total_web_sales,
       AVG(ws.ws_ext_sales_price) AS avg_sales_price,
       ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY COUNT(DISTINCT cr.cr_order_number) DESC) AS return_rank
FROM item i
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
WHERE i.i_category NOT IN ('Electronics','Books','Clothing')
  AND i.i_current_price > 50
GROUP BY i.i_category
HAVING COUNT(DISTINCT cr.cr_order_number) > 10
ORDER BY return_rank
LIMIT 5
