SELECT d.cd_education_status,
       COUNT(*) AS customer_cnt,
       AVG(d.cd_dep_count) AS avg_dep_count
FROM tpcds.customer c
JOIN tpcds.customer_demographics d
  ON c.c_current_cdemo_sk = d.cd_demo_sk
WHERE c.c_birth_month = 3
  AND c.c_birth_country = 'MEXICO'
  AND d.cd_credit_rating = 'Low Risk'
GROUP BY d.cd_education_status
ORDER BY customer_cnt DESC
