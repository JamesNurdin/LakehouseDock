SELECT
    cd_gender,
    cd_marital_status,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(*) AS cnt_customers
FROM tpcds.customer_demographics
WHERE cd_dep_employed_count >= 3
  AND cd_dep_college_count <= 4
GROUP BY cd_gender, cd_marital_status
ORDER BY avg_purchase_estimate DESC
