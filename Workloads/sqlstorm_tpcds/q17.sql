SELECT s.s_store_name, SUM(ss.ss_net_profit) AS total_profit
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
GROUP BY s.s_store_name
ORDER BY total_profit DESC
LIMIT 10
