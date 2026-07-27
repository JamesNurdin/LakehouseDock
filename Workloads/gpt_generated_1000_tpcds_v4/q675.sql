SELECT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cd.cd_gender,
    cd.cd_credit_rating
FROM catalog_sales cs
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE cs.cs_promo_sk IN (817, 1036)
  AND cd.cd_credit_rating = 'Good'
ORDER BY cs.cs_ext_sales_price DESC
LIMIT 100
