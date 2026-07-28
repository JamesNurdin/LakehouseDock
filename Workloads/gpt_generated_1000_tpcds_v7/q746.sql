SELECT c_customer_id,
       c_first_name,
       c_last_name,
       c_birth_year
FROM   tpcds.customer
WHERE  c_current_cdemo_sk = 877565
  AND  c_first_shipto_date_sk = 2449976
ORDER BY c_customer_id
