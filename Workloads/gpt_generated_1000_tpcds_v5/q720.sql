SELECT
  d.d_year AS sales_year,
  cd.cd_gender AS gender,
  t.t_shift AS shift,
  COUNT(*) AS sales_cnt,
  SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
  AVG(ss.ss_ext_discount_amt) AS avg_discount,
  MIN(ss.ss_ext_sales_price) AS min_sales_price,
  MAX(ss.ss_ext_sales_price) AS max_sales_price,
  CASE
    WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High'
    WHEN SUM(ss.ss_net_profit) > 0    THEN 'Medium'
    ELSE 'Low'
  END AS profit_category
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year = 2002
  AND d.d_current_year = 'Y'
  AND t.t_shift = 'first'
  AND ss.ss_ext_list_price > 1000
  AND cd.cd_education_status = 'College'
GROUP BY d.d_year, cd.cd_gender, t.t_shift
ORDER BY total_net_paid DESC
LIMIT 100
