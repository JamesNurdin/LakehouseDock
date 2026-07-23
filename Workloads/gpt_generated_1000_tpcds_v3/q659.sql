WITH base_sales AS (
   SELECT
       s.s_store_id,
       i.i_item_id,
       i.i_category,
       SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
       SUM(ss.ss_ext_sales_price) AS total_store_sales,
       SUM(cs.cs_net_profit) AS total_catalog_profit,
       SUM(ss.ss_net_profit) AS total_store_profit,
       CASE
           WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High'
           ELSE 'Low'
       END AS sales_tier
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE cs.cs_coupon_amt > 500.00
     AND cs.cs_ext_wholesale_cost BETWEEN 1000 AND 4000
     AND s.s_country = 'United States'
     AND ss.ss_wholesale_cost > 30.00
   GROUP BY s.s_store_id, i.i_item_id, i.i_category
   HAVING SUM(cs.cs_ext_sales_price) > 50000
)
SELECT
   s_store_id,
   i_item_id,
   i_category,
   total_catalog_sales,
   total_store_sales,
   total_catalog_profit,
   total_store_profit,
   sales_tier
FROM base_sales
WHERE sales_tier = 'High'
UNION ALL
SELECT
   s.s_store_id,
   i.i_item_id,
   i.i_category,
   SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
   SUM(ss.ss_ext_sales_price) AS total_store_sales,
   SUM(cs.cs_net_profit) AS total_catalog_profit,
   SUM(ss.ss_net_profit) AS total_store_profit,
   CASE
       WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High'
       ELSE 'Low'
   END AS sales_tier
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE cs.cs_coupon_amt = 0.00
  AND cs.cs_ext_wholesale_cost < 2000
  AND s.s_suite_number = 'Suite T   '
  AND ss.ss_ext_tax < 100.00
GROUP BY s.s_store_id, i.i_item_id, i.i_category
HAVING SUM(ss.ss_ext_sales_price) > 30000
ORDER BY total_catalog_sales DESC
LIMIT 200
