SELECT
    cd_gender,
    cd_education_status,
    cd_purchase_estimate,
    cd_dep_count
FROM tpcds.customer_demographics
WHERE cd_education_status = 'College'
  AND cd_dep_count >= 2
ORDER BY cd_purchase_estimate DESC
LIMIT 100
