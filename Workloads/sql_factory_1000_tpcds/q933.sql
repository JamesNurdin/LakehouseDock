SELECT
  i.i_category,
  COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
  COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  AVG(ws.ws_ext_sales_price) FILTER (WHERE ws.ws_quantity > 5) AS avg_big_sales,
  SUM(cr.cr_return_amount) - SUM(sr.sr_return_amt) AS net_return_diff,
  DENSE_RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_dense_rank
FROM item i
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
WHERE i.i_category LIKE 'C%'
GROUP BY i.i_category
HAVING SUM(ws.ws_ext_sales_price) > 5000
ORDER BY sales_dense_rank
FETCH FIRST 4 ROWS ONLY
