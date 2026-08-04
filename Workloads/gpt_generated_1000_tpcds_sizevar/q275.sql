SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(s.ss_net_paid) AS total_net_paid,
    COUNT(*) AS purchase_count
FROM tpcds.customer AS c
JOIN tpcds.store_sales AS s
  ON s.ss_customer_sk = c.c_customer_sk
WHERE c.c_birth_year = 1960
  AND s.ss_wholesale_cost < 20.00
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
HAVING SUM(s.ss_net_paid) > 5000
ORDER BY total_net_paid DESC
LIMIT 50
