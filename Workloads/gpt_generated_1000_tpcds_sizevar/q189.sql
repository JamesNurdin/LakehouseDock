SELECT
  cd_gender,
  AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM tpcds.customer_demographics
WHERE cd_dep_employed_count >= 2
  AND cd_purchase_estimate > 5000
GROUP BY cd_gender
ORDER BY avg_purchase_estimate DESC
