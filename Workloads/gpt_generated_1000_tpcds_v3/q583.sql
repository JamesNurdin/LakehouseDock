SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       cs.cs_ext_sales_price
FROM tpcds.catalog_sales cs
JOIN tpcds.customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE cs.cs_wholesale_cost > 50.00
  AND c.c_birth_country = 'JAPAN'
ORDER BY cs.cs_ext_sales_price DESC
LIMIT 100
