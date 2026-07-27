SELECT
    c.c_customer_id AS customer_id,
    cd.cd_gender AS gender,
    SUM(cs.cs_ext_sales_price) AS total_amount,
    CASE WHEN SUM(cs.cs_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'LOW' END AS amount_category,
    'catalog_sales' AS source
FROM catalog_sales cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND cd.cd_purchase_estimate > 2000
GROUP BY c.c_customer_id, cd.cd_gender

UNION ALL

SELECT
    cust.c_customer_id AS customer_id,
    dem.cd_gender AS gender,
    SUM(sr.sr_return_amt_inc_tax) AS total_amount,
    CASE WHEN SUM(sr.sr_return_amt_inc_tax) > 5000 THEN 'HIGH' ELSE 'LOW' END AS amount_category,
    'store_returns' AS source
FROM store_returns sr
JOIN customer cust ON sr.sr_customer_sk = cust.c_customer_sk
JOIN customer_demographics dem ON sr.sr_cdemo_sk = dem.cd_demo_sk
WHERE cust.c_preferred_cust_flag = 'Y'
  AND dem.cd_purchase_estimate > 2000
GROUP BY cust.c_customer_id, dem.cd_gender

LIMIT 100
