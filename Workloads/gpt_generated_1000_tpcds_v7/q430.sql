SELECT
    c_salutation,
    c_birth_month,
    COUNT(*) AS customer_count
FROM
    tpcds.customer
WHERE
    c_salutation = 'Mrs.'
    AND c_birth_month IN (5, 6)
GROUP BY
    c_salutation,
    c_birth_month
ORDER BY
    customer_count DESC
