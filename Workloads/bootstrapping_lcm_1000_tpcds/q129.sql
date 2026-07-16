SELECT
  (d_ret.d_year * 100 + d_ret.d_moy) AS year_month,
  s.s_state,
  hd_refunded.hd_income_band_sk AS refunded_income_band,
  hd_returning.hd_income_band_sk AS returning_income_band,
  p.p_promo_name,
  COUNT(DISTINCT wr.wr_order_number) AS num_orders,
  SUM(wr.wr_return_quantity) AS total_return_qty,
  SUM(wr.wr_return_amt) AS total_return_amt,
  SUM(wr.wr_net_loss) AS total_net_loss,
  AVG(p.p_cost) AS avg_promo_cost,
  SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS total_active_discount_cost,
  COUNT(*) FILTER (WHERE wr.wr_net_loss > 0) AS positive_loss_cnt,
  COUNT(*) FILTER (WHERE wr.wr_net_loss < 0) AS negative_loss_cnt
FROM web_returns wr
JOIN date_dim d_ret
  ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_refunded
  ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
  ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN store s
  ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN promotion p
  ON p.p_start_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year >= 2000
GROUP BY
  (d_ret.d_year * 100 + d_ret.d_moy),
  s.s_state,
  hd_refunded.hd_income_band_sk,
  hd_returning.hd_income_band_sk,
  p.p_promo_name
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
