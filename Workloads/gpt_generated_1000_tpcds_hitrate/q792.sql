SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       d.d_date
FROM tpcds.customer c
JOIN tpcds.date_dim d
  ON c.c_first_shipto_date_sk = d.d_date_sk
WHERE c.c_email_address LIKE '%@V.com'
  AND d.d_qoy = 2
ORDER BY d.d_date DESC
LIMIT 10
