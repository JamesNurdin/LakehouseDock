SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       d.d_date AS first_sales_date
FROM tpcds.customer c
JOIN tpcds.date_dim d
  ON c.c_first_sales_date_sk = d.d_date_sk
WHERE c.c_salutation = 'Mr.'
  AND c.c_first_sales_date_sk = 2451903
  AND d.d_year = 2001
LIMIT 100
