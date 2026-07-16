SELECT s.s_store_name,
       SUM(ss.ss_net_profit) AS total_profit
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_year = 2000
GROUP BY s.s_store_name
ORDER BY total_profit DESC
LIMIT 10
