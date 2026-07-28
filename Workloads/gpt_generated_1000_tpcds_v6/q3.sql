SELECT cd_gender,
       cd_marital_status,
       AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM tpcds.customer_demographics
WHERE cd_dep_count >= 2
  AND cd_education_status = 'College'
GROUP BY cd_gender, cd_marital_status
ORDER BY avg_purchase_estimate DESC
LIMIT 100
