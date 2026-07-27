SELECT DISTINCT cd.cd_gender,
                cd.cd_education_status,
                sr.sr_reason_sk,
                sr.sr_fee
FROM tpcds.store_returns AS sr
JOIN tpcds.customer_demographics AS cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
WHERE sr.sr_fee > 30.00
  AND cd.cd_dep_count <= 2
  AND cd.cd_education_status = 'Advanced Degree'
LIMIT 100
