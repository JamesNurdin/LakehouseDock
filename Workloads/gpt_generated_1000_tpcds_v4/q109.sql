SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_paid) AS total_net_paid
FROM tpcds.customer AS c
JOIN tpcds.store_sales AS ss
  ON ss.ss_customer_sk = c.c_customer_sk
WHERE ss.ss_ext_list_price > 1000
  AND c.c_birth_day = 31
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_net_paid DESC
LIMIT 100
