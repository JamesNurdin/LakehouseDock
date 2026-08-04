SELECT
  cd.cd_gender,
  cd.cd_marital_status,
  SUM(cs.cs_net_paid) AS total_net_paid
FROM tpcds.catalog_sales cs
JOIN tpcds.customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE cs.cs_ext_wholesale_cost > 1500.00
  AND cd.cd_marital_status = 'M'
GROUP BY cd.cd_gender, cd.cd_marital_status
ORDER BY total_net_paid DESC
