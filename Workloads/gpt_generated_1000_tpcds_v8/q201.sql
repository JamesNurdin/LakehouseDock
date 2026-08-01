SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit
FROM tpcds.customer AS c
JOIN tpcds.store_sales AS ss
  ON ss.ss_customer_sk = c.c_customer_sk
WHERE ss.ss_ext_tax > 20.00
  AND c.c_birth_day = 21
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_sales DESC
LIMIT 100
