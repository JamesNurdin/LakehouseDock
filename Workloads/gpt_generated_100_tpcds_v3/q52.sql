SELECT cs.cs_order_number,
       cs.cs_net_paid_inc_ship_tax,
       cd.cd_gender,
       cd.cd_education_status
FROM catalog_sales cs
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE cs.cs_ship_mode_sk = 12
  AND cd.cd_purchase_estimate >= 3000
ORDER BY cs.cs_net_paid_inc_ship_tax DESC
LIMIT 10
