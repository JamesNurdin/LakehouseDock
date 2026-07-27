WITH store_agg AS (
   SELECT i.i_item_id,
          i.i_product_name,
          SUM(ss.ss_ext_sales_price) AS sales_amount,
          'store' AS source
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE s.s_state = 'CA'
     AND ss.ss_ext_sales_price > 1000
   GROUP BY i.i_item_id, i.i_product_name
),
catalog_agg AS (
   SELECT i.i_item_id,
          i.i_product_name,
          SUM(cs.cs_ext_sales_price) AS sales_amount,
          'catalog' AS source
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE p.p_channel_tv = 'N'
     AND cs.cs_ext_sales_price > 1000
   GROUP BY i.i_item_id, i.i_product_name
),
union_all_sales AS (
   SELECT * FROM store_agg
   UNION ALL
   SELECT * FROM catalog_agg
)
SELECT u.i_item_id,
       u.i_product_name,
       SUM(u.sales_amount) AS total_sales,
       COUNT(DISTINCT u.source) AS source_count
FROM union_all_sales u
WHERE u.sales_amount > (
   SELECT AVG(sales_amount) FROM union_all_sales
)
GROUP BY u.i_item_id, u.i_product_name
ORDER BY total_sales DESC
LIMIT 100
