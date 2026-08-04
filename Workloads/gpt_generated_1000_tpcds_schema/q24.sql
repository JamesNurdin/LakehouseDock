SELECT
    c_birth_year,
    COUNT(*) AS customer_count
FROM tpcds.customer
WHERE c_birth_month = 4
  AND c_last_review_date > 2452360
GROUP BY c_birth_year
ORDER BY customer_count DESC
