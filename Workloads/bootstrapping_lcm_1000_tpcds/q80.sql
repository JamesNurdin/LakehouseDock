SELECT
  s.s_store_id,
  s.s_store_name,
  d.d_year,
  d.d_moy,
  COUNT(DISTINCT cs.cs_order_number) AS num_orders,
  SUM(cs.cs_net_paid) AS total_sales_net_paid,
  SUM(cs.cs_net_profit) AS total_sales_net_profit,
  SUM(cs.cs_quantity) AS total_quantity_sold,
  SUM(cr.cr_return_amount) AS total_catalog_return_amount,
  SUM(cr.cr_net_loss) AS total_catalog_net_loss,
  SUM(sr.sr_return_amt) AS total_store_return_amount,
  SUM(sr.sr_net_loss) AS total_store_net_loss,
  SUM(cs.cs_net_paid) - COALESCE(SUM(cr.cr_return_amount), 0) - COALESCE(SUM(sr.sr_return_amt), 0) AS net_revenue,
  CASE
    WHEN SUM(cs.cs_net_paid) > 0 THEN
      (COALESCE(SUM(cr.cr_return_amount), 0) + COALESCE(SUM(sr.sr_return_amt), 0)) / SUM(cs.cs_net_paid) * 100
    ELSE NULL
  END AS return_rate_percent,
  AVG(date_diff('day', d.d_date, d_cr_ret.d_date)) AS avg_days_to_catalog_return,
  AVG(date_diff('day', d.d_date, d_closed.d_date)) AS avg_days_to_store_closed,
  AVG(date_diff('day', d.d_date, d_ship.d_date)) AS avg_shipping_days,
  SUM(CASE WHEN cs.cs_quantity > 5 THEN 1 ELSE 0 END) AS large_quantity_orders,
  SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
  SUM(cs.cs_ext_sales_price) AS total_sales_price,
  CASE
    WHEN SUM(cs.cs_ext_sales_price) > 0 THEN SUM(cs.cs_ext_discount_amt) / SUM(cs.cs_ext_sales_price) * 100
    ELSE NULL
  END AS discount_rate_percent,
  AVG(cs.cs_net_profit / NULLIF(cs.cs_net_paid, 0)) * 100 AS avg_profit_margin_percent
FROM date_dim d
JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_item_sk = cs.cs_item_sk
 AND cr.cr_order_number = cs.cs_order_number
LEFT JOIN date_dim d_cr_ret
  ON cr.cr_returned_date_sk = d_cr_ret.d_date_sk
JOIN store_returns sr
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed
  ON s.s_closed_date_sk = d_closed.d_date_sk
GROUP BY
  s.s_store_id,
  s.s_store_name,
  d.d_year,
  d.d_moy
HAVING
  SUM(cs.cs_net_paid) > 1000
ORDER BY
  net_revenue DESC
LIMIT 100
