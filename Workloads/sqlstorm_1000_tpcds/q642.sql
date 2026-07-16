SELECT c.c_customer_id,
       SUM(ss.ss_net_paid) AS total_net_paid,
       SUM(ss.ss_net_profit) AS total_profit,
       COUNT(*) AS transaction_count
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2000
GROUP BY c.c_customer_id
ORDER BY total_net_paid DESC
LIMIT 10
