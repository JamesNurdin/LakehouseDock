SELECT
  cd_gender,
  COUNT(DISTINCT cd_marital_status) AS distinct_marital_status_cnt
FROM tpcds.customer_demographics
WHERE cd_education_status = 'Advanced Degree'
  AND cd_dep_employed_count >= 2
GROUP BY cd_gender
ORDER BY distinct_marital_status_cnt DESC
LIMIT 100
