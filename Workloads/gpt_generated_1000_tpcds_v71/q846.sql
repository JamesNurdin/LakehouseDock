WITH base1 AS (
  SELECT
    s.s_store_id AS store_id,
    d_sales.d_year AS year,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    SUM(sr.sr_return_amt) AS store_return_amount,
    (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS global_max_income
  FROM
    store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_sales.d_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sales.d_date_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_sales.d_date_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE
    d_sales.d_year = 2001
    AND s.s_state = 'TX'
    AND ib.ib_upper_bound > 50000
    AND t_sales.t_hour BETWEEN 9 AND 17
    AND EXISTS (
      SELECT 1
      FROM promotion p2
      WHERE p2.p_promo_sk = ss.ss_promo_sk
        AND p2.p_start_date_sk IN (
          SELECT d2.d_date_sk FROM date_dim d2 WHERE d2.d_year = 2000
        )
    )
  GROUP BY
    s.s_store_id,
    d_sales.d_year
),
base2 AS (
  SELECT
    s.s_store_id AS store_id,
    d_sales.d_year AS year,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    SUM(sr.sr_return_amt) AS store_return_amount,
    (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS global_max_income
  FROM
    store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_sales.d_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sales.d_date_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_sales.d_date_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE
    d_sales.d_year = 2002
    AND s.s_state = 'CA'
    AND ib.ib_upper_bound > 60000
    AND t_sales.t_hour BETWEEN 10 AND 18
    AND NOT EXISTS (
      SELECT 1
      FROM promotion p2
      WHERE p2.p_promo_sk = ss.ss_promo_sk
        AND p2.p_start_date_sk IN (
          SELECT d2.d_date_sk FROM date_dim d2 WHERE d2.d_year = 2000
        )
    )
  GROUP BY
    s.s_store_id,
    d_sales.d_year
),
combined AS (
  SELECT * FROM base1
  UNION ALL
  SELECT * FROM base2
)
SELECT
  year,
  AVG(total_sales) AS avg_sales_per_store,
  SUM(total_profit) AS total_profit_all,
  COUNT(*) AS store_count,
  MAX(global_max_income) AS max_income_band
FROM combined
GROUP BY year
HAVING AVG(total_sales) > 50000
ORDER BY avg_sales_per_store DESC
LIMIT 100
