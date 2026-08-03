WITH joined_data AS (
   SELECT
       cr.cr_returned_date_sk,
       cr.cr_returned_time_sk,
       cr.cr_order_number,
       cr.cr_return_amount,
       cr.cr_net_loss,
       cp.cp_department,
       s.s_store_sk,
       d.d_year,
       hd.hd_income_band_sk,
       t.t_hour,
       t.t_minute,
       t.t_second
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 2001
     AND t.t_hour BETWEEN 9 AND 17
     AND cp.cp_department = 'Electronics'
     AND hd.hd_income_band_sk = 5
),
web_data AS (
   SELECT
       wr.wr_returned_date_sk,
       wr.wr_returned_time_sk,
       wr.wr_order_number,
       wr.wr_return_amt,
       wr.wr_net_loss,
       d2.d_year,
       t2.t_hour,
       hd2.hd_income_band_sk
   FROM web_returns wr
   JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
   JOIN time_dim t2 ON wr.wr_returned_time_sk = t2.t_time_sk
   JOIN household_demographics hd2 ON wr.wr_returning_hdemo_sk = hd2.hd_demo_sk
   WHERE d2.d_year = 2001
     AND t2.t_hour BETWEEN 9 AND 17
     AND hd2.hd_income_band_sk = 5
),
catalog_max AS (
   SELECT
       cr_order_number,
       MAX(cr_return_amount) AS max_return_amount
   FROM catalog_returns
   GROUP BY cr_order_number
)
(
SELECT
   jd.s_store_sk,
   jd.cp_department,
   jd.d_year,
   COUNT(DISTINCT jd.cr_order_number) AS catalog_order_cnt,
   COUNT(DISTINCT wd.wr_order_number) AS web_order_cnt,
   SUM(jd.cr_return_amount) AS total_catalog_return_amount,
   SUM(wd.wr_return_amt) AS total_web_return_amount,
   SUM(jd.cr_net_loss) - SUM(wd.wr_net_loss) AS net_loss_diff,
   lm.max_return_amount
FROM joined_data jd
LEFT JOIN web_data wd
   ON jd.cr_returned_date_sk = wd.wr_returned_date_sk
  AND jd.cr_returned_time_sk = wd.wr_returned_time_sk
  AND jd.cr_order_number = wd.wr_order_number
LEFT JOIN LATERAL (
   SELECT max_return_amount
   FROM catalog_max cm
   WHERE cm.cr_order_number = jd.cr_order_number
) lm ON true
GROUP BY jd.s_store_sk, jd.cp_department, jd.d_year, lm.max_return_amount
HAVING SUM(jd.cr_return_amount) > 1000
)
EXCEPT
(
SELECT
   jd.s_store_sk,
   jd.cp_department,
   jd.d_year,
   COUNT(DISTINCT jd.cr_order_number) AS catalog_order_cnt,
   COUNT(DISTINCT wd.wr_order_number) AS web_order_cnt,
   SUM(jd.cr_return_amount) AS total_catalog_return_amount,
   SUM(wd.wr_return_amt) AS total_web_return_amount,
   SUM(jd.cr_net_loss) - SUM(wd.wr_net_loss) AS net_loss_diff,
   lm.max_return_amount
FROM joined_data jd
LEFT JOIN web_data wd
   ON jd.cr_returned_date_sk = wd.wr_returned_date_sk
  AND jd.cr_returned_time_sk = wd.wr_returned_time_sk
  AND jd.cr_order_number = wd.wr_order_number
LEFT JOIN LATERAL (
   SELECT max_return_amount
   FROM catalog_max cm
   WHERE cm.cr_order_number = jd.cr_order_number
) lm ON true
GROUP BY jd.s_store_sk, jd.cp_department, jd.d_year, lm.max_return_amount
)
ORDER BY net_loss_diff DESC
LIMIT 100
