SELECT
  d_ret.d_year,
  d_ret.d_quarter_name,
  d_ret.d_month_seq,
  hd_refunded.hd_demo_sk AS refunded_demo_sk,
  hd_refunded.hd_buy_potential AS refunded_buy_potential,
  hd_returning.hd_demo_sk AS returning_demo_sk,
  hd_returning.hd_buy_potential AS returning_buy_potential,
  s.s_state,
  s.s_city,
  s.s_market_desc,
  s.s_floor_space,
  wp.wp_type,
  wp.wp_url,
  COUNT(*) AS total_returns,
  SUM(wr.wr_return_amt) AS total_return_amount,
  SUM(wr.wr_return_tax) AS total_return_tax,
  AVG(wr.wr_return_quantity) AS avg_return_quantity,
  SUM(wr.wr_fee) AS total_fee,
  SUM(wr.wr_net_loss) AS total_net_loss,
  MIN(d_creation.d_date) AS page_creation_date,
  MAX(d_access.d_date) AS page_last_access_date
FROM web_returns wr
JOIN date_dim d_ret
  ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_refunded
  ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
  ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation
  ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
  ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_ret.d_date_sk
GROUP BY
  d_ret.d_year,
  d_ret.d_quarter_name,
  d_ret.d_month_seq,
  hd_refunded.hd_demo_sk,
  hd_refunded.hd_buy_potential,
  hd_returning.hd_demo_sk,
  hd_returning.hd_buy_potential,
  s.s_state,
  s.s_city,
  s.s_market_desc,
  s.s_floor_space,
  wp.wp_type,
  wp.wp_url
ORDER BY total_return_amount DESC
LIMIT 100
