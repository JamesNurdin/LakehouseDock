WITH
  cat AS (
    SELECT
      ib.ib_income_band_sk AS income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      t_cat.t_hour AS hour_of_day,
      cr.cr_net_loss AS net_loss,
      1 AS catalog_return_cnt,
      0 AS web_return_cnt
    FROM catalog_returns cr
    JOIN customer cust_refunded ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
    JOIN customer cust_returning ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
    JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN time_dim t_cat ON cr.cr_returned_time_sk = t_cat.t_time_sk
    JOIN income_band ib ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
  ),
  web AS (
    SELECT
      ib_w.ib_income_band_sk AS income_band_sk,
      ib_w.ib_lower_bound,
      ib_w.ib_upper_bound,
      t_web.t_hour AS hour_of_day,
      wr.wr_net_loss AS net_loss,
      0 AS catalog_return_cnt,
      1 AS web_return_cnt
    FROM web_returns wr
    JOIN customer cust_refunded_w ON wr.wr_refunded_customer_sk = cust_refunded_w.c_customer_sk
    JOIN customer cust_returning_w ON wr.wr_returning_customer_sk = cust_returning_w.c_customer_sk
    JOIN customer_demographics cd_refunded_w ON wr.wr_refunded_cdemo_sk = cd_refunded_w.cd_demo_sk
    JOIN customer_demographics cd_returning_w ON wr.wr_returning_cdemo_sk = cd_returning_w.cd_demo_sk
    JOIN household_demographics hd_refunded_w ON wr.wr_refunded_hdemo_sk = hd_refunded_w.hd_demo_sk
    JOIN household_demographics hd_returning_w ON wr.wr_returning_hdemo_sk = hd_returning_w.hd_demo_sk
    JOIN time_dim t_web ON wr.wr_returned_time_sk = t_web.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN income_band ib_w ON hd_refunded_w.hd_income_band_sk = ib_w.ib_income_band_sk
  ),
  combined AS (
    SELECT * FROM cat
    UNION ALL
    SELECT * FROM web
  ),
  agg AS (
    SELECT
      income_band_sk,
      ib_lower_bound,
      ib_upper_bound,
      hour_of_day,
      SUM(net_loss) AS total_net_loss,
      SUM(catalog_return_cnt) AS catalog_return_cnt,
      SUM(web_return_cnt) AS web_return_cnt
    FROM combined
    GROUP BY income_band_sk, ib_lower_bound, ib_upper_bound, hour_of_day
  )
SELECT
  income_band_sk,
  ib_lower_bound,
  ib_upper_bound,
  hour_of_day,
  total_net_loss,
  catalog_return_cnt,
  web_return_cnt,
  SUM(total_net_loss) OVER (PARTITION BY income_band_sk ORDER BY hour_of_day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_loss_by_hour,
  RANK() OVER (PARTITION BY income_band_sk ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
