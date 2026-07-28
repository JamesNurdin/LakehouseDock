WITH bill_sales AS (
   SELECT
       cs.cs_order_number AS cs_order_number,
       cs.cs_ext_sales_price AS cs_ext_sales_price,
       cs.cs_ext_tax AS cs_ext_tax,
       cd.cd_gender AS cd_gender,
       cd.cd_education_status AS cd_education_status,
       ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY cs.cs_ext_sales_price DESC) AS rn
   FROM catalog_sales cs
   JOIN customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   WHERE cs.cs_ship_mode_sk IN (1, 2)
     AND cd.cd_purchase_estimate > 2000
),
ship_sales AS (
   SELECT
       cs.cs_order_number AS cs_order_number,
       cs.cs_ext_sales_price AS cs_ext_sales_price,
       cs.cs_ext_tax AS cs_ext_tax,
       cd.cd_gender AS cd_gender,
       cd.cd_education_status AS cd_education_status,
       ROW_NUMBER() OVER (PARTITION BY cs.cs_ship_customer_sk ORDER BY cs.cs_ext_sales_price DESC) AS rn
   FROM catalog_sales cs
   JOIN customer_demographics cd
     ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
   WHERE cs.cs_ext_tax > 100
     AND cd.cd_dep_college_count >= 4
)
SELECT
    cs_order_number,
    cs_ext_sales_price,
    cs_ext_tax,
    cd_gender,
    cd_education_status,
    rn
FROM bill_sales
UNION ALL
SELECT
    cs_order_number,
    cs_ext_sales_price,
    cs_ext_tax,
    cd_gender,
    cd_education_status,
    rn
FROM ship_sales
LIMIT 100
