SELECT d.d_year,
       d.d_moy,
       SUM(ss.ss_net_profit) AS total_net_profit
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, d.d_moy
ORDER BY total_net_profit DESC
LIMIT 10
