SELECT
    s.s_store_id,
    d.d_year,
    SUM(ws.ws_ext_sales_price)                     AS total_sales,
    SUM(ws.ws_net_profit)                         AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number)            AS distinct_orders,
    COUNT(DISTINCT cr.cr_order_number)            AS catalog_returns_cnt,
    COUNT(DISTINCT wr.wr_order_number)            AS web_returns_cnt,
    SUM(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_return_amount ELSE 0 END) AS total_catalog_return_amount,
    SUM(CASE WHEN wr.wr_return_quantity > 0 THEN wr.wr_return_amt ELSE 0 END)    AS total_web_return_amount,
    SUM(CASE WHEN ws.ws_quantity < 5 THEN ws.ws_ext_sales_price ELSE 0 END)       AS small_quantity_sales,
    SUM(CASE WHEN ws.ws_quantity >= 5 THEN ws.ws_ext_sales_price ELSE 0 END)      AS large_quantity_sales
FROM catalog_returns AS cr
JOIN date_dim AS d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_sales AS ws
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_returns AS wr
  ON wr.wr_returned_date_sk = d.d_date_sk
 AND wr.wr_item_sk          = ws.ws_item_sk
 AND wr.wr_order_number    = ws.ws_order_number
JOIN store AS s
  ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY s.s_store_id, d.d_year
HAVING COUNT(DISTINCT ws.ws_order_number) > 10
ORDER BY total_sales DESC
LIMIT 100
