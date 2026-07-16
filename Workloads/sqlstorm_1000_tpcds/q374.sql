SELECT s.s_store_name,
       d.d_year,
       SUM(ss.ss_net_paid) AS total_net_paid,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       COUNT(*) AS transaction_count
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY s.s_store_name, d.d_year
ORDER BY total_net_paid DESC
LIMIT 10
