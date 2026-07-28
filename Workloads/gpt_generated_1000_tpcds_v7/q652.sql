/*
  Goal: Analyze catalog return performance by year, department and web site, broken down by customers' income bands, focusing on morning returns with amounts greater than $100 and income bands whose upper bound is at most $80,000.
*/
SELECT
  dr.d_year AS return_year,
  cp.cp_department,
  ws.web_name,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  COUNT(cr.cr_order_number) AS return_count,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(cr.cr_return_amount) AS avg_return_amount,
  MIN(cr.cr_return_amount) AS min_return_amount,
  MAX(cr.cr_return_amount) AS max_return_amount
FROM catalog_returns cr
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim dr
  ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN time_dim td
  ON cr.cr_returned_time_sk = td.t_time_sk
JOIN customer c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_site ws
  ON ws.web_open_date_sk = dr.d_date_sk
WHERE td.t_sub_shift = 'morning'
  AND cr.cr_return_amount > 100.0
  AND ib.ib_upper_bound <= 80000
GROUP BY
  dr.d_year,
  cp.cp_department,
  ws.web_name,
  ib.ib_lower_bound,
  ib.ib_upper_bound
ORDER BY total_return_amount DESC
