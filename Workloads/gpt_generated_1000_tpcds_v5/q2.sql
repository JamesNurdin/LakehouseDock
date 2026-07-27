SELECT cd_gender,
       cd_education_status,
       COUNT(*) AS demographic_cnt
FROM tpcds.customer_demographics
WHERE cd_dep_count >= 3
  AND cd_gender = 'F'
GROUP BY cd_gender, cd_education_status
ORDER BY demographic_cnt DESC
LIMIT 100
