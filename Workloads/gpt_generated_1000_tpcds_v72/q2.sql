SELECT
  c_customer_id,
  c_first_name,
  c_last_name,
  c_birth_year,
  c_preferred_cust_flag
FROM tpcds.customer
WHERE c_birth_year BETWEEN 1950 AND 1970
  AND c_preferred_cust_flag = 'Y'
ORDER BY c_birth_year DESC
LIMIT 100
