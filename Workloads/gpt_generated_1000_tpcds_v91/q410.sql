SELECT cd_gender,
       COUNT(DISTINCT cd_marital_status) AS distinct_marital_status_cnt,
       COUNT(*) AS total_customers
FROM tpcds.customer_demographics
WHERE cd_purchase_estimate >= 6000
  AND cd_dep_employed_count >= 4
GROUP BY cd_gender
ORDER BY distinct_marital_status_cnt DESC, cd_gender
