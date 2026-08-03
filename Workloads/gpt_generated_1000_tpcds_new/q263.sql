SELECT cd.cd_gender,
       COUNT(DISTINCT c.c_customer_id) AS num_customers,
       AVG(cd.cd_purchase_estimate) AS avg_estimate
FROM tpcds.customer AS c
JOIN tpcds.customer_demographics AS cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_purchase_estimate > 5000
  AND cd.cd_marital_status = 'M'
GROUP BY cd.cd_gender
ORDER BY num_customers DESC
