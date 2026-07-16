SELECT
  dd_sold.d_year AS sales_year,
  dd_sold.d_month_seq AS sales_month_seq,
  sm_sales.sm_type AS ship_mode_type,
  s.s_store_name AS store_name,
  s.s_city AS store_city,
  COUNT(DISTINCT cs.cs_order_number) AS num_orders,
  SUM(cs.cs_net_paid) AS total_sales_net_paid,
  SUM(cs.cs_net_profit) AS total_sales_net_profit,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(cr.cr_net_loss) AS total_return_loss,
  (SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss)) AS net_profit_after_returns,
  AVG(cs.cs_quantity) AS avg_quantity_per_order,
  SUM(cs.cs_ext_tax) AS total_sales_tax,
  SUM(cr.cr_return_tax) AS total_return_tax,
  SUM(cs.cs_coupon_amt) AS total_sales_coupon_amt,
  SUM(cr.cr_fee) AS total_return_fee,
  AVG(date_diff('day', dd_sold.d_date, dd_ship.d_date)) AS avg_shipping_delay_days,
  AVG(date_diff('day', dd_ship.d_date, dd_return.d_date)) AS avg_return_delay_days
FROM
  catalog_sales cs
JOIN catalog_returns cr
  ON cs.cs_order_number = cr.cr_order_number
 AND cs.cs_item_sk = cr.cr_item_sk
JOIN ship_mode sm_sales
  ON cs.cs_ship_mode_sk = sm_sales.sm_ship_mode_sk
JOIN ship_mode sm_return
  ON cr.cr_ship_mode_sk = sm_return.sm_ship_mode_sk
JOIN date_dim dd_sold
  ON cs.cs_sold_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_ship
  ON cs.cs_ship_date_sk = dd_ship.d_date_sk
JOIN date_dim dd_return
  ON cr.cr_returned_date_sk = dd_return.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = dd_sold.d_date_sk
WHERE dd_sold.d_year >= 2000
GROUP BY
  dd_sold.d_year,
  dd_sold.d_month_seq,
  sm_sales.sm_type,
  s.s_store_name,
  s.s_city
ORDER BY
  net_profit_after_returns DESC,
  total_sales_net_paid DESC
LIMIT 100
