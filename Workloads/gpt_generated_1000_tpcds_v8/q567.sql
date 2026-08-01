SELECT DISTINCT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       c.c_birth_year
FROM tpcds.customer AS c
WHERE c.c_current_hdemo_sk IN (6374, 6580)
  AND c.c_first_shipto_date_sk BETWEEN 2450000 AND 2453000
LIMIT 100
