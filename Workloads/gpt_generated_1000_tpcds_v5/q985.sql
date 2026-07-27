SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    c_birth_country,
    c_birth_year
FROM tpcds.customer
WHERE c_birth_country = 'MEXICO'
  AND c_birth_year >= 1980
ORDER BY c_last_name ASC, c_first_name ASC
