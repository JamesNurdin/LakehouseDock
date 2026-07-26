SELECT
  i.i_category,
  COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
  SUM(CASE WHEN sr.sr_return_quantity > 1 THEN sr.sr_return_amt ELSE 0 END) AS store_return_amount_multi_qty,
  SUM(ws.ws_ext_sales_price) AS total_ws_sales,
  SUM(ws.ws_ext_sales_price) / NULLIF(COUNT(DISTINCT i.i_item_sk), 0) AS sales_per_item,
  ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_ext_sales_price) ASC) AS asc_sales_rank
FROM item i
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_return_amount > 0
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_ext_sales_price > 0
WHERE i.i_category IN ('Electronics', 'Books', 'Clothing') AND i.i_current_price BETWEEN 10 AND 1000
GROUP BY i.i_category
ORDER BY asc_sales_rank DESC
LIMIT 3
