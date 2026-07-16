SELECT d.d_year, s.s_state, sum(ss.ss_net_paid) AS total_sales
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_year BETWEEN 1998 AND 2002
GROUP BY d.d_year, s.s_state
ORDER BY d.d_year, total_sales DESC
LIMIT 100
