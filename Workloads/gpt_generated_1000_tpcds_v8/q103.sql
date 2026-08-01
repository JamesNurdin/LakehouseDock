SELECT DISTINCT
    c.c_first_name,
    c.c_last_name,
    s.ss_store_sk,
    s.ss_net_paid
FROM tpcds.customer AS c
JOIN tpcds.store_sales AS s
  ON s.ss_customer_sk = c.c_customer_sk
WHERE s.ss_net_paid > 1000
  AND c.c_birth_day = 13
  AND s.ss_store_sk IN (772, 805)
LIMIT 100
