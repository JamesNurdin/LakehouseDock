WITH returns_a AS (
   SELECT
       cp.cp_catalog_page_id AS catalog_page_id,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_cnt,
       CASE WHEN SUM(cr.cr_return_amount) > 500 THEN 'High' ELSE 'Low' END AS return_category
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE i.i_category_id IN (4, 6)
     AND cp.cp_type = 'A'
     AND cr.cr_return_quantity > 1
   GROUP BY cp.cp_catalog_page_id
),
returns_b AS (
   SELECT
       cp.cp_catalog_page_id AS catalog_page_id,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_cnt,
       CASE WHEN SUM(cr.cr_return_amount) > 500 THEN 'High' ELSE 'Low' END AS return_category
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE i.i_brand = 'BrandX'
     AND cp.cp_type = 'B'
     AND cr.cr_reversed_charge > 50
   GROUP BY cp.cp_catalog_page_id
)
SELECT *
FROM returns_a
UNION ALL
SELECT *
FROM returns_b
ORDER BY return_category DESC, total_return_amount DESC
LIMIT 100
