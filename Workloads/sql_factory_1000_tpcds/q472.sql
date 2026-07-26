SELECT
  i.i_category,
  COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
  COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
  SUM(ws.ws_ext_sales_price) AS total_web_sales,
  SUM(ws.ws_ext_sales_price) / NULLIF(COUNT(DISTINCT i.i_item_sk),0) AS avg_sales_per_item,
  RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
FROM item i
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
WHERE i.i_category IN ('Electronics','Books','Clothing')
GROUP BY i.i_category
ORDER BY sales_rank
OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY
