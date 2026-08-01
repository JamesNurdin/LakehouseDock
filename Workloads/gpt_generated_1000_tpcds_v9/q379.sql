SELECT c.c_customer_id, c.c_first_name, c.c_last_name, d.cd_gender, d.cd_purchase_estimate
FROM tpcds.customer AS c
JOIN tpcds.customer_demographics AS d ON c.c_current_cdemo_sk = d.cd_demo_sk
WHERE d.cd_purchase_estimate >= 5000 AND c.c_birth_month = 5
ORDER BY d.cd_purchase_estimate DESC, c.c_customer_id
LIMIT 100
