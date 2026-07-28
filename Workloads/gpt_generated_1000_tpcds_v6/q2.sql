SELECT
    c_customer_id,
    c_salutation,
    c_first_name,
    c_last_name,
    c_birth_year
FROM tpcds.customer
WHERE c_salutation = 'Mrs.'
  AND c_birth_year BETWEEN 1970 AND 1980
LIMIT 100
