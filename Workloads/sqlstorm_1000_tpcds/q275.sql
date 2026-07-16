SELECT d.d_year, d.d_quarter_name, SUM(ss.ss_net_paid) AS total_net_paid, SUM(ss.ss_net_profit) AS total_net_profit
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
GROUP BY d.d_year, d.d_quarter_name
ORDER BY d.d_year, d.d_quarter_name
