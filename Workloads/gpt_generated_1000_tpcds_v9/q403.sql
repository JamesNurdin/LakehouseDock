SELECT cd_demo_sk,
       cd_gender,
       cd_marital_status,
       cd_purchase_estimate,
       cd_dep_college_count
FROM tpcds.customer_demographics
WHERE cd_marital_status = 'M'
  AND cd_purchase_estimate >= 8000
ORDER BY cd_purchase_estimate DESC
LIMIT 100
