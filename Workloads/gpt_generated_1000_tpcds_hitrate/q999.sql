WITH filtered_pages AS (
   SELECT cp.*
   FROM catalog_page cp
   WHERE cp.cp_catalog_page_sk IN (
         SELECT cr.cr_catalog_page_sk
         FROM catalog_returns cr
         WHERE cr.cr_return_amount > 100
       )
     AND regexp_like(cp.cp_catalog_page_id, '^A{5,}')
     AND cp.cp_description LIKE '%summer%'
),
page_keys_to_exclude AS (
   SELECT DISTINCT cr.cr_catalog_page_sk
   FROM catalog_returns cr
   WHERE cr.cr_return_quantity = 0
),
remaining_pages AS (
   SELECT cp.cp_catalog_page_sk
   FROM filtered_pages cp
   EXCEPT
   SELECT pk.cr_catalog_page_sk FROM page_keys_to_exclude pk
),
joined_data AS (
   SELECT
      cp.cp_catalog_page_sk,
      cp.cp_catalog_page_id,
      cp.cp_department,
      cp.cp_catalog_number,
      cp.cp_catalog_page_number,
      cp.cp_description,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_net_loss
   FROM catalog_page cp
   JOIN catalog_returns cr
     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE cp.cp_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM remaining_pages)
),
aggregated AS (
   SELECT
      cp_department,
      cp_catalog_number,
      any_value(cp_catalog_page_id) AS cp_catalog_page_id,
      SUM(cr_return_amount) AS total_return_amount,
      SUM(cr_return_quantity) AS total_return_qty,
      SUM(cr_net_loss) AS total_net_loss,
      COUNT(*) AS cnt,
      ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY SUM(cr_return_amount) DESC) AS dept_rank
   FROM joined_data
   GROUP BY GROUPING SETS (
      (cp_department, cp_catalog_number),
      (cp_department)
   )
)
SELECT
   cp_department,
   cp_catalog_number,
   total_return_amount,
   total_return_qty,
   total_net_loss,
   cnt,
   dept_rank,
   regexp_extract(cp_catalog_page_id, '(A{3,})', 1) AS id_prefix,
   CONCAT(cp_department, '-', CAST(cp_catalog_number AS VARCHAR)) AS dept_catalog_key
FROM aggregated
WHERE dept_rank <= 3
ORDER BY cp_department, total_return_amount DESC
LIMIT 100
