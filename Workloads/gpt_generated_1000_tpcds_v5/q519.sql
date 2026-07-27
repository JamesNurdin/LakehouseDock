WITH sales AS (
   SELECT
       cd.cd_demo_sk,
       'billing' AS role,
       SUM(cs.cs_ext_sales_price) AS total_amount,
       COUNT(*) AS transaction_count,
       (
           SELECT AVG(cd2.cd_purchase_estimate)
           FROM customer_demographics cd2
           WHERE cd2.cd_demo_sk = cd.cd_demo_sk
       ) AS avg_purchase_estimate
   FROM catalog_sales cs
   JOIN customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   WHERE cs.cs_sales_price > 30
   GROUP BY cd.cd_demo_sk
),
returns AS (
   SELECT
       cd.cd_demo_sk,
       'refunded' AS role,
       SUM(wr.wr_return_amt_inc_tax) AS total_amount,
       COUNT(*) AS transaction_count,
       (
           SELECT AVG(cd2.cd_purchase_estimate)
           FROM customer_demographics cd2
           WHERE cd2.cd_demo_sk = cd.cd_demo_sk
       ) AS avg_purchase_estimate
   FROM web_returns wr
   JOIN customer_demographics cd
     ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE wr.wr_fee > 20
     AND EXISTS (
         SELECT 1
         FROM web_page wp
         WHERE wp.wp_web_page_sk = wr.wr_web_page_sk
           AND wp.wp_type = 'product'
     )
   GROUP BY cd.cd_demo_sk
)
SELECT *
FROM sales
UNION ALL
SELECT *
FROM returns
ORDER BY total_amount DESC
LIMIT 100
