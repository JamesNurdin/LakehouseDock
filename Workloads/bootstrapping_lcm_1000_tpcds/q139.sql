SELECT
  s.s_store_id,
  s.s_store_name,
  s.s_city,
  dd_return.d_date AS return_date,
  dd_return.d_year,
  dd_return.d_month_seq,
  td.t_hour,
  td.t_meal_time,
  COUNT(*) AS return_cnt,
  SUM(sr.sr_return_amt) AS total_return_amt,
  SUM(sr.sr_net_loss) AS total_net_loss,
  COUNT(DISTINCT p.p_promo_id) AS active_promo_cnt,
  MAX(p.p_discount_active) AS max_discount_active,
  dd_closed.d_date AS store_closed_date,
  dd_closed.d_current_year AS store_closed_year,
  dd_start.d_date AS promo_start_date,
  dd_end.d_date AS promo_end_date
FROM store_returns sr
JOIN date_dim dd_return
  ON sr.sr_returned_date_sk = dd_return.d_date_sk
JOIN time_dim td
  ON sr.sr_return_time_sk = td.t_time_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim dd_closed
  ON s.s_closed_date_sk = dd_closed.d_date_sk
LEFT JOIN promotion p
  ON p.p_start_date_sk <= dd_return.d_date_sk
     AND p.p_end_date_sk >= dd_return.d_date_sk
LEFT JOIN date_dim dd_start
  ON p.p_start_date_sk = dd_start.d_date_sk
LEFT JOIN date_dim dd_end
  ON p.p_end_date_sk = dd_end.d_date_sk
GROUP BY
  s.s_store_id,
  s.s_store_name,
  s.s_city,
  dd_return.d_date,
  dd_return.d_year,
  dd_return.d_month_seq,
  td.t_hour,
  td.t_meal_time,
  dd_closed.d_date,
  dd_closed.d_current_year,
  dd_start.d_date,
  dd_end.d_date
ORDER BY total_net_loss DESC
LIMIT 100
