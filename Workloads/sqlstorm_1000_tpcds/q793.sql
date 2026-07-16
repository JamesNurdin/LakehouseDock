SELECT d.d_year,
       SUM(s.ss_net_paid) AS total_paid,
       SUM(s.ss_net_profit) AS total_profit,
       SUM(s.ss_quantity) AS total_quantity
FROM store_sales s
JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year
ORDER BY d.d_year
