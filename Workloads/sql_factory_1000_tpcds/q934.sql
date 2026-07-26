SELECT
  i.i_category,
  COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
  SUM(sr.sr_return_amt) AS total_store_return_amount,
  SUM(ws.ws_ext_sales_price) AS total_web_sales,
  SUM(ws.ws_ext_sales_price) / NULLIF(COUNT(DISTINCT ws.ws_item_sk), 0) AS sales_per_unique_item,
  RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(sr.sr_return_amt) DESC) AS store_return_rank
FROM item i
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_return_quantity >= 2
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_return_quantity BETWEEN 1 AND 3
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_quantity > 0
WHERE i.i_category IN ('Electronics', 'Books', 'Clothing')
GROUP BY i.i_category
ORDER BY store_return_rank ASC
OFFSET 2 ROWS FETCH NEXT 3 ROWS ONLY
