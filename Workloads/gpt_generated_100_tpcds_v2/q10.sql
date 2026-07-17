SELECT d.d_year,
       d.d_moy,
       SUM(ss.ss_net_paid) AS total_net_paid
FROM tpcds.store_sales ss
JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, d.d_moy
