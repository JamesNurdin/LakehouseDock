SELECT
  cd_gender,
  cd_marital_status,
  AVG(cd_purchase_estimate) AS avg_estimate
FROM tpcds.customer_demographics
WHERE cd_purchase_estimate > 7000
  AND cd_dep_count <= 2
GROUP BY cd_gender, cd_marital_status
ORDER BY avg_estimate DESC
