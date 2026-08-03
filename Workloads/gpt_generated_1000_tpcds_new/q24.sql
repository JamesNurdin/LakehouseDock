SELECT d.d_year,
       d.d_month_seq,
       SUM(ss.ss_net_paid) AS total_net_paid,
       COUNT(*) AS sales_cnt
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_weekend = 'N'
  AND ss.ss_ext_wholesale_cost > 1000
GROUP BY d.d_year, d.d_month_seq
ORDER BY d.d_year, d.d_month_seq
