WITH catalog_sales_agg AS (
   SELECT
       cs_bill_customer_sk AS customer_sk,
       SUM(cs_ext_sales_price) AS sales_amount,
       'Catalog' AS sales_source
   FROM catalog_sales
   JOIN customer ON cs_bill_customer_sk = customer.c_customer_sk
   JOIN customer_demographics cd ON cs_bill_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_gender = 'M'
   GROUP BY cs_bill_customer_sk
),
store_sales_agg AS (
   SELECT
       ss_customer_sk AS customer_sk,
       SUM(ss_ext_sales_price) AS sales_amount,
       'Store' AS sales_source
   FROM store_sales
   JOIN customer ON ss_customer_sk = customer.c_customer_sk
   JOIN customer_demographics cd ON ss_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_gender = 'M'
   GROUP BY ss_customer_sk
),
combined AS (
   SELECT
       ca.customer_sk,
       c.c_first_name,
       c.c_last_name,
       ca.sales_amount,
       ca.sales_source
   FROM catalog_sales_agg ca
   JOIN customer c ON ca.customer_sk = c.c_customer_sk

   UNION ALL

   SELECT
       sa.customer_sk,
       c.c_first_name,
       c.c_last_name,
       sa.sales_amount,
       sa.sales_source
   FROM store_sales_agg sa
   JOIN customer c ON sa.customer_sk = c.c_customer_sk
)
SELECT
   customer_sk,
   c_first_name,
   c_last_name,
   sales_source,
   sales_amount,
   ROW_NUMBER() OVER (PARTITION BY sales_source ORDER BY sales_amount DESC) AS sales_rank
FROM combined
ORDER BY sales_amount DESC
LIMIT 100
