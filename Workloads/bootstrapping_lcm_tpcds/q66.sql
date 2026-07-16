SELECT
  cr.cd_gender AS refunded_gender,
  crs.cd_gender AS returning_gender,
  dr_ret.d_year AS return_year,
  dr_ret.d_month_seq AS return_month,
  s.s_store_name,
  s.s_state,
  wp.wp_type,
  dr_create.d_month_seq AS page_creation_month,
  dr_access.d_day_name AS page_access_day,
  SUM(wr.wr_return_amt) AS total_return_amount,
  COUNT(*) AS total_returns,
  AVG(wr.wr_return_quantity) AS avg_return_quantity,
  SUM(wr.wr_net_loss) AS total_net_loss
FROM web_returns wr
JOIN customer_demographics cr
  ON wr.wr_refunded_cdemo_sk = cr.cd_demo_sk
JOIN customer_demographics crs
  ON wr.wr_returning_cdemo_sk = crs.cd_demo_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim dr_ret
  ON wr.wr_returned_date_sk = dr_ret.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = dr_ret.d_date_sk
JOIN date_dim dr_create
  ON wp.wp_creation_date_sk = dr_create.d_date_sk
JOIN date_dim dr_access
  ON wp.wp_access_date_sk = dr_access.d_date_sk
WHERE dr_ret.d_year = 2021
GROUP BY
  cr.cd_gender,
  crs.cd_gender,
  dr_ret.d_year,
  dr_ret.d_month_seq,
  s.s_store_name,
  s.s_state,
  wp.wp_type,
  dr_create.d_month_seq,
  dr_access.d_day_name
ORDER BY total_return_amount DESC
LIMIT 100
