SELECT
    c_salutation,
    COUNT(*) AS customer_cnt,
    MIN(c_birth_year) AS youngest_birth_year
FROM tpcds.customer
WHERE c_last_review_date BETWEEN 2452300 AND 2452400
  AND c_birth_day IN (5, 22, 27)
GROUP BY c_salutation
ORDER BY customer_cnt DESC
LIMIT 10
