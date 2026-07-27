WITH filtered_sales AS (
   SELECT
       cs.cs_item_sk,
       cs.cs_catalog_page_sk,
       cs.cs_ext_sales_price,
       cs.cs_order_number
   FROM catalog_sales cs
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE cp.cp_department = 'DEPARTMENT'
     AND regexp_like(cp.cp_description, '(?i)electronics')
),
sales_agg AS (
   SELECT
       fs.cs_item_sk,
       fs.cs_catalog_page_sk,
       SUM(fs.cs_ext_sales_price) AS total_sales,
       COUNT(DISTINCT fs.cs_order_number) AS distinct_orders
   FROM filtered_sales fs
   GROUP BY fs.cs_item_sk, fs.cs_catalog_page_sk
),
distinct_items AS (
   SELECT DISTINCT cs_item_sk, cs_catalog_page_sk
   FROM catalog_sales
   WHERE cs_quantity > 0
)
SELECT
   i.i_item_id,
   i.i_product_name,
   substring(i.i_product_name, 1, 12) AS prod_name_short,
   cp.cp_catalog_page_id,
   cp.cp_department,
   regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS three_digit_seq,
   CASE WHEN regexp_like(i.i_item_desc, '[A-Z]{2,}') THEN 'HAS_UPPER' ELSE 'NO_UPPER' END AS upper_flag,
   sa.total_sales,
   sa.distinct_orders
FROM sales_agg sa
JOIN distinct_items di
  ON sa.cs_item_sk = di.cs_item_sk
 AND sa.cs_catalog_page_sk = di.cs_catalog_page_sk
JOIN item i
  ON sa.cs_item_sk = i.i_item_sk
JOIN catalog_page cp
  ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE i.i_item_desc LIKE '%SMALL%'
  AND concat(cp.cp_department, '-', i.i_color) LIKE 'DEPARTMENT-%'
ORDER BY sa.total_sales DESC
LIMIT 100
