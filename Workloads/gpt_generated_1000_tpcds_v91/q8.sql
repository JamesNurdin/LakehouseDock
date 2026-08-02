SELECT cd_credit_rating,
       cd_education_status,
       COUNT(*) AS customer_count,
       AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM tpcds.customer_demographics
WHERE cd_credit_rating = 'Good'
  AND cd_dep_college_count > 0
GROUP BY cd_credit_rating, cd_education_status
ORDER BY customer_count DESC
LIMIT 100
