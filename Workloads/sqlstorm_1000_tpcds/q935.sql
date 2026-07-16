SELECT d.d_year, d.d_month_seq, SUM(ss.ss_net_profit) AS total_profit
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
GROUP BY d.d_year, d.d_month_seq
ORDER BY total_profit DESC
LIMIT 10
