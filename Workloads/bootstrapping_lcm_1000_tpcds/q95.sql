SELECT
  d_sold.d_year AS sale_year,
  d_sold.d_month_seq AS sale_month_seq,
  d_ship.d_week_seq AS ship_week_seq,
  s.s_store_name,
  s.s_state AS store_state,
  ws.web_name,
  ws.web_state AS website_state,
  d_return.d_year AS return_year,
  d_return.d_month_seq AS return_month_seq,
  date_diff('day', d_return.d_date, d_close.d_date) AS website_lifespan_days,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(cs.cs_net_profit) AS total_net_profit,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(cr.cr_net_loss) AS total_net_loss,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  AVG(cs.cs_quantity) AS avg_quantity,
  CASE WHEN SUM(cr.cr_return_amount) > 0 THEN 'Returned' ELSE 'No Return' END AS return_flag,
  SUM(cr.cr_return_amount) / NULLIF(SUM(cs.cs_net_paid), 0) AS return_to_sales_ratio
FROM catalog_returns cr
JOIN catalog_sales cs
  ON cr.cr_item_sk = cs.cs_item_sk
  AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_return.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d_return.d_date_sk
JOIN date_dim d_close
  ON ws.web_close_date_sk = d_close.d_date_sk
GROUP BY
  d_sold.d_year,
  d_sold.d_month_seq,
  d_ship.d_week_seq,
  s.s_store_name,
  s.s_state,
  ws.web_name,
  ws.web_state,
  d_return.d_year,
  d_return.d_month_seq,
  date_diff('day', d_return.d_date, d_close.d_date)
HAVING SUM(cs.cs_net_paid) > 0
ORDER BY total_net_paid DESC
LIMIT 100
