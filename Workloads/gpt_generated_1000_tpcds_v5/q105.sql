SELECT
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_ext_sales_price,
    cd.cd_purchase_estimate
FROM tpcds.catalog_sales cs
JOIN tpcds.customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'F'
  AND cd.cd_purchase_estimate > 5000
  AND cs.cs_ext_list_price > 1000
ORDER BY cs.cs_ext_sales_price DESC
LIMIT 100
