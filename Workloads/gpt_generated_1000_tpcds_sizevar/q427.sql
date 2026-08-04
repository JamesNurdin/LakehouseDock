SELECT
    c_birth_country,
    COUNT(*) AS customer_count
FROM tpcds.customer
WHERE c_current_hdemo_sk IN (3876, 2777)
  AND c_birth_country = 'FIJI'
GROUP BY c_birth_country
