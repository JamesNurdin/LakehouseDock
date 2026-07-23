SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       SUM(cs.cs_net_paid) AS total_net_paid,
       COUNT(*) AS order_count
FROM catalog_sales cs
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE cs.cs_warehouse_sk = 1
  AND c.c_salutation = 'Mr.'
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_net_paid DESC
LIMIT 100
