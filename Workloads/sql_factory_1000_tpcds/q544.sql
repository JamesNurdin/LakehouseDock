SELECT i.i_category,
       COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
       SUM(CASE WHEN sr.sr_return_quantity > 5 THEN sr.sr_return_quantity ELSE 0 END) AS high_qty_store_returns,
       SUM(ws.ws_ext_sales_price) AS total_web_sales,
       AVG(ws.ws_ext_sales_price) OVER (PARTITION BY i.i_category) AS avg_sales_by_category,
       DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_dense_rank
FROM item i
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
WHERE i.i_category LIKE 'C%'
GROUP BY i.i_category, ws.ws_ext_sales_price
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY sales_dense_rank
FETCH FIRST 4 ROWS ONLY
