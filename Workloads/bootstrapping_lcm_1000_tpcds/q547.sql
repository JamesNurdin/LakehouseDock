SELECT
  d_return.d_year,
  d_return.d_month_seq,
  i.i_category,
  i.i_class,
  p.p_promo_name,
  s.s_state,
  COUNT(DISTINCT wr.wr_order_number) AS num_orders,
  SUM(wr.wr_return_quantity) AS total_return_qty,
  SUM(wr.wr_return_amt) AS total_return_amt,
  SUM(wr.wr_net_loss) AS total_net_loss,
  SUM(p.p_cost) AS total_promo_cost,
  AVG(s.s_tax_percentage) AS avg_tax_pct,
  CASE WHEN d_return.d_dow IN (6,7) THEN 'Weekend' ELSE 'Weekday' END AS return_day_type,
  (d_end.d_date_sk - d_start.d_date_sk) AS promo_duration_days,
  CASE WHEN SUM(wr.wr_return_amt) = 0 THEN 0 ELSE SUM(p.p_cost) / SUM(wr.wr_return_amt) END AS promo_cost_to_return_ratio,
  ROUND(AVG(wr.wr_return_quantity), 2) AS avg_return_qty_per_order
FROM web_returns wr
JOIN date_dim d_return
  ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN item i
  ON wr.wr_item_sk = i.i_item_sk
JOIN promotion p
  ON i.i_item_sk = p.p_item_sk
JOIN date_dim d_start
  ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
  ON p.p_end_date_sk = d_end.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_return.d_year BETWEEN 2020 AND 2022
  AND s.s_state IS NOT NULL
GROUP BY
  d_return.d_year,
  d_return.d_month_seq,
  i.i_category,
  i.i_class,
  p.p_promo_name,
  s.s_state,
  CASE WHEN d_return.d_dow IN (6,7) THEN 'Weekend' ELSE 'Weekday' END,
  (d_end.d_date_sk - d_start.d_date_sk)
ORDER BY total_return_amt DESC
LIMIT 50
