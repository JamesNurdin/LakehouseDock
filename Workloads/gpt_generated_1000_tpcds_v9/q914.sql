WITH
store_sales_agg AS (
  SELECT
    i.i_item_id AS item_id,
    i.i_item_desc AS item_desc,
    i.i_category AS category,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    CAST(NULL AS decimal(7,2)) AS total_catalog_sales,
    REGEXP_EXTRACT(i.i_item_desc, '([0-9]+)', 1) AS numeric_part_in_desc
  FROM store_sales ss
  FULL OUTER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  WHERE i.i_item_id IS NOT NULL
  GROUP BY i.i_item_id, i.i_item_desc, i.i_category, REGEXP_EXTRACT(i.i_item_desc, '([0-9]+)', 1)
  HAVING SUM(ss.ss_ext_sales_price) > 1000
),
catalog_sales_agg AS (
  SELECT
    i.i_item_id AS item_id,
    i.i_item_desc AS item_desc,
    i.i_category AS category,
    CAST(NULL AS decimal(7,2)) AS total_store_sales,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    REGEXP_EXTRACT(i.i_item_desc, '([0-9]+)', 1) AS numeric_part_in_desc
  FROM catalog_sales cs
  RIGHT OUTER JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  WHERE i.i_item_id IS NOT NULL
  GROUP BY i.i_item_id, i.i_item_desc, i.i_category, REGEXP_EXTRACT(i.i_item_desc, '([0-9]+)', 1)
  HAVING SUM(cs.cs_ext_sales_price) > 500
)
SELECT
  agg.item_id,
  CONCAT(agg.item_desc, ' - ', agg.category) AS full_desc,
  SUBSTRING(agg.item_desc FROM 1 FOR 10) AS short_desc,
  agg.numeric_part_in_desc,
  COALESCE(agg.total_store_sales, 0) AS total_store_sales,
  COALESCE(agg.total_catalog_sales, 0) AS total_catalog_sales,
  (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_item_sk = i.i_item_sk) AS return_count
FROM (
  SELECT
    item_id,
    item_desc,
    category,
    total_store_sales,
    total_catalog_sales,
    numeric_part_in_desc
  FROM store_sales_agg
  UNION DISTINCT
  SELECT
    item_id,
    item_desc,
    category,
    total_store_sales,
    total_catalog_sales,
    numeric_part_in_desc
  FROM catalog_sales_agg
) agg
JOIN item i
  ON agg.item_id = i.i_item_id
WHERE
  REGEXP_LIKE(agg.item_desc, '^.*[A-Z]{2}[0-9]*$')
  AND agg.item_desc LIKE '%AAA%'
  AND agg.item_id IN (
    SELECT i2.i_item_id FROM item i2 WHERE i2.i_brand LIKE 'B%'
  )
ORDER BY total_store_sales DESC, total_catalog_sales DESC
LIMIT 100
