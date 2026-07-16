SELECT d.d_year,
       sum(ss.ss_net_paid) AS total_net_paid,
       sum(ss.ss_net_profit) AS total_net_profit,
       count(*) AS sales_cnt
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year
ORDER BY d.d_year
