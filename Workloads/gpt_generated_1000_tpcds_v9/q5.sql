SELECT
  cd_education_status,
  cd_gender,
  COUNT(*) AS customer_cnt
FROM
  tpcds.customer AS c
JOIN
  tpcds.customer_demographics AS cd
ON
  c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE
  c.c_salutation = 'Dr.'
  AND cd.cd_dep_college_count >= 2
GROUP BY
  cd_education_status,
  cd_gender
ORDER BY
  customer_cnt DESC
LIMIT 100
