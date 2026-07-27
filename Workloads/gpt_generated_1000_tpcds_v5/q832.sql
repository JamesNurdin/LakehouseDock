WITH avg_price_cte AS (
   SELECT avg(ss_sales_price) AS avg_price
   FROM store_sales
),

brand_sales_a AS (
   SELECT
      i.i_brand,
      i.i_brand_id,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt,
      CONCAT(i.i_brand, ' - ', i.i_product_name) AS brand_product,
      ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS brand_rank,
      SUBSTRING(i.i_item_id, 1, 3) AS item_prefix,
      REGEXP_EXTRACT(i.i_item_desc, '(\\d+)', 1) AS extracted_number
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE REGEXP_LIKE(i.i_item_desc, '^.*[0-9]{3}.*$')
     AND i.i_units LIKE 'Each%'
   GROUP BY i.i_brand, i.i_brand_id, i.i_product_name, i.i_item_id, i.i_item_desc
   HAVING SUM(ss.ss_ext_sales_price) > (SELECT avg_price FROM avg_price_cte)
),

brand_sales_b AS (
   SELECT
      i.i_brand,
      i.i_brand_id,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt,
      CONCAT(i.i_brand, ' - ', i.i_product_name) AS brand_product,
      ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS brand_rank,
      SUBSTRING(i.i_item_id, 1, 3) AS item_prefix,
      REGEXP_EXTRACT(i.i_item_desc, '(\\d+)', 1) AS extracted_number
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE i.i_units LIKE 'Lb%'
     AND REGEXP_LIKE(i.i_item_desc, '.*[A-Z]{2,}$')
   GROUP BY i.i_brand, i.i_brand_id, i.i_product_name, i.i_item_id, i.i_item_desc
   HAVING SUM(ss.ss_ext_sales_price) > (SELECT avg_price FROM avg_price_cte)
)

SELECT
   combined.i_brand,
   combined.i_brand_id,
   combined.total_sales,
   combined.sales_cnt,
   combined.brand_product,
   combined.brand_rank,
   combined.item_prefix,
   combined.extracted_number
FROM (
   SELECT i_brand, i_brand_id, total_sales, sales_cnt, brand_product, brand_rank, item_prefix, extracted_number
   FROM brand_sales_a
   UNION ALL
   SELECT i_brand, i_brand_id, total_sales, sales_cnt, brand_product, brand_rank, item_prefix, extracted_number
   FROM brand_sales_b
) AS combined
WHERE combined.brand_rank <= 5
ORDER BY combined.total_sales DESC
LIMIT 100
