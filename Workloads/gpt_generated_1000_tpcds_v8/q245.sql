SELECT DISTINCT
    cu.c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    cd.cd_gender
FROM tpcds.customer cu
JOIN tpcds.customer_demographics cd
  ON cu.c_current_cdemo_sk = cd.cd_demo_sk
WHERE cu.c_birth_month = 5
  AND cd.cd_marital_status = 'M'
ORDER BY cu.c_customer_id
