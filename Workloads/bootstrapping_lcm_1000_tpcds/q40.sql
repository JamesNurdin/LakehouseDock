SELECT
  (d_return.d_year - (d_return.d_year % 5)) AS return_year_bucket,
  MIN(d_return.d_year) AS min_return_year,
  d_sold.d_year AS sold_year,
  d_ship.d_year AS ship_year,
  sm.sm_type,
  s.s_state,
  COUNT(*) AS total_transactions,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(cr.cr_net_loss) AS total_net_loss,
  SUM(cs.cs_ext_discount_amt) AS total_discount,
  AVG(cs.cs_quantity) AS avg_quantity,
  SUM(CASE WHEN cr.cr_return_quantity > 0 THEN 1 ELSE 0 END) AS returns_count,
  SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS total_profit,
  SUM(CASE WHEN sm.sm_carrier = 'UPS' THEN cs.cs_ext_ship_cost ELSE 0 END) AS ups_ship_cost
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
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  AND cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s
  ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_return.d_year BETWEEN 2000 AND 2005
  AND sm.sm_type IN ('AIR', 'GROUND')
GROUP BY
  (d_return.d_year - (d_return.d_year % 5)),
  d_sold.d_year,
  d_ship.d_year,
  sm.sm_type,
  s.s_state
HAVING COUNT(*) > 100
ORDER BY total_net_paid DESC
LIMIT 100
