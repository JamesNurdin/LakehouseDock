SELECT
  w.w_warehouse_name,
  d.d_year,
  d.d_month_seq,
  COUNT(*) AS total_returns,
  SUM(cr.cr_net_loss) AS total_net_loss,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(cr.cr_return_tax) AS avg_return_tax,
  AVG(ib.ib_upper_bound) AS avg_income_upper_bound,
  AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
  SUM(p.p_cost) AS total_promo_cost,
  COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
  RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_net_loss) DESC) AS warehouse_loss_rank
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer c
  ON cr.cr_returning_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN promotion p
  ON p.p_start_date_sk = d.d_date_sk
LEFT JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
     AND wp.wp_creation_date_sk = d.d_date_sk
WHERE cr.cr_fee > 30
  AND d.d_year BETWEEN 2000 AND 2002
GROUP BY w.w_warehouse_name, d.d_year, d.d_month_seq
ORDER BY d.d_year, d.d_month_seq, total_net_loss DESC
LIMIT 100
