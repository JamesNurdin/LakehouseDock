SELECT DISTINCT
    ss.ss_store_sk,
    cd.cd_gender,
    cd.cd_education_status
FROM store_sales ss
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE ss.ss_net_paid_inc_tax >= 1000.00
  AND cd.cd_marital_status = 'M'
ORDER BY ss.ss_store_sk ASC
LIMIT 100
