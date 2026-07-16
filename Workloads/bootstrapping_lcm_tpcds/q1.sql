SELECT
  d.d_date,
  d.d_year,
  d.d_month_seq,
  COUNT(DISTINCT cr.cr_order_number)               AS catalog_return_orders,
  SUM(cr.cr_net_loss)                              AS catalog_net_loss,
  COUNT(DISTINCT ws.ws_order_number)               AS web_sales_orders,
  SUM(ws.ws_net_profit)                            AS web_sales_net_profit,
  COUNT(DISTINCT wr.wr_order_number)               AS web_return_orders,
  SUM(wr.wr_net_loss)                              AS web_return_net_loss,
  COUNT(DISTINCT s.s_store_id)                     AS stores_closed,
  SUM(ws.ws_ext_sales_price)                       AS total_web_sales,
  SUM(ws.ws_ext_discount_amt)                      AS total_discount,
  SUM(wr.wr_return_amt)                            AS total_web_return_amount,
  SUM(cr.cr_return_amount)                         AS total_catalog_return_amount
FROM date_dim d
LEFT JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
GROUP BY d.d_date, d.d_year, d.d_month_seq
ORDER BY d.d_date DESC
