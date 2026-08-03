WITH catalog_item_sales AS (
   SELECT
       cs.cs_item_sk,
       i.i_product_name AS product_name,
       i.i_item_desc,
       SUM(cs.cs_net_paid) AS total_net_paid,
       SUM(cs.cs_net_profit) AS total_net_profit,
       COUNT(*) AS sales_cnt,
       CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_level,
       REGEXP_EXTRACT(i.i_item_desc, '(\\d{3}[A-Z]{2})', 1) AS extracted_code
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_education_status LIKE 'College%'
     AND REGEXP_LIKE(i.i_item_desc, '\\d{3}[A-Z]{2}')
   GROUP BY cs.cs_item_sk, i.i_product_name, i.i_item_desc
),
store_item_set AS (
   SELECT DISTINCT ss.ss_item_sk AS item_sk
   FROM store_sales ss
),
catalog_not_in_store AS (
   SELECT cs_item_sk
   FROM catalog_item_sales
   EXCEPT
   SELECT item_sk
   FROM store_item_set
)
SELECT
   cis.cs_item_sk,
   cis.product_name,
   cis.total_net_paid,
   cis.total_net_profit,
   cis.sales_cnt,
   cis.profit_level,
   cis.extracted_code,
   (
       SELECT AVG(ws.ws_sales_price)
       FROM web_sales ws
       WHERE ws.ws_item_sk = cis.cs_item_sk
   ) AS avg_web_sales_price,
   CASE
       WHEN EXISTS (
           SELECT 1
           FROM catalog_returns cr
           WHERE cr.cr_item_sk = cis.cs_item_sk
             AND cr.cr_return_quantity > 0
       ) THEN 'HAS_RETURN'
       ELSE 'NO_RETURN'
   END AS return_flag
FROM catalog_item_sales cis
JOIN catalog_not_in_store cns ON cis.cs_item_sk = cns.cs_item_sk
ORDER BY cis.total_net_paid DESC
LIMIT 100
