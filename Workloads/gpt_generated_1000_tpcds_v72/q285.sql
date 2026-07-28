SELECT
  c.c_customer_id,
  c.c_birth_country,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(cs.cs_ext_list_price) AS total_list_price
FROM tpcds.catalog_sales cs
JOIN tpcds.customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE cs.cs_net_paid > 1000
  AND c.c_birth_country = 'MONACO'
GROUP BY c.c_customer_id, c.c_birth_country
ORDER BY total_net_paid DESC
LIMIT 100
