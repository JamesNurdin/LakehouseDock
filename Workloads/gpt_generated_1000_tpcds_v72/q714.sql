WITH demo AS (
    SELECT cd_demo_sk,
           cd_gender
    FROM   customer_demographics
)
SELECT d.cd_gender AS gender,
       'Catalog'      AS source,
       CASE WHEN cs.cs_quantity > 5 THEN 'High' ELSE 'Low' END AS qty_category,
       SUM(cs.cs_ext_sales_price) AS total_amount
FROM   catalog_sales cs
JOIN   demo d
       ON cs.cs_bill_cdemo_sk = d.cd_demo_sk
JOIN   catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE  cp.cp_catalog_page_number BETWEEN 10 AND 20
GROUP  BY d.cd_gender,
          CASE WHEN cs.cs_quantity > 5 THEN 'High' ELSE 'Low' END

UNION ALL

SELECT d.cd_gender AS gender,
       'Store'       AS source,
       CASE WHEN ss.ss_quantity > 5 THEN 'High' ELSE 'Low' END AS qty_category,
       SUM(ss.ss_ext_sales_price) AS total_amount
FROM   store_sales ss
JOIN   demo d
       ON ss.ss_cdemo_sk = d.cd_demo_sk
WHERE  ss.ss_sold_date_sk BETWEEN 2450905 AND 2451115
GROUP  BY d.cd_gender,
          CASE WHEN ss.ss_quantity > 5 THEN 'High' ELSE 'Low' END

ORDER BY gender,
         source,
         qty_category
