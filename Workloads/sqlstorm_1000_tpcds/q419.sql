SELECT c.c_first_name,
       c.c_last_name,
       SUM(ss.ss_ext_sales_price) AS total_spent
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
GROUP BY c.c_first_name, c.c_last_name
ORDER BY total_spent DESC
LIMIT 10
