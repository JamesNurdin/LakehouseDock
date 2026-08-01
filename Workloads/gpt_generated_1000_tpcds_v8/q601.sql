SELECT cd_education_status,
       COUNT(*) AS customer_count,
       AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM tpcds.customer_demographics
WHERE cd_dep_count >= 3
  AND cd_credit_rating = 'Excellent'
GROUP BY cd_education_status
ORDER BY customer_count DESC
