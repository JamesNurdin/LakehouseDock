SELECT c.c_first_name,
       c.c_last_name,
       SUM(cs.cs_net_paid_inc_ship_tax) AS total_paid
FROM tpcds.catalog_sales cs
JOIN tpcds.customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE cs.cs_bill_customer_sk = 939392
  AND c.c_salutation = 'Ms.'
GROUP BY c.c_first_name, c.c_last_name
