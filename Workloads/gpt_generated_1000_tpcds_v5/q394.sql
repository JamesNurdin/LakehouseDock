SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  SUM(cs.cs_net_paid_inc_ship_tax) AS total_paid
FROM tpcds.catalog_sales cs
JOIN tpcds.customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE cs.cs_net_paid_inc_ship_tax > 2000
  AND c.c_birth_day = 23
GROUP BY
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name
ORDER BY total_paid DESC
LIMIT 100
