SELECT
    cp_catalog_page_id,
    cp_department,
    cp_catalog_page_number,
    cp_catalog_page_number * 2 AS double_page_number
FROM catalog_page
WHERE cp_department = 'DEPARTMENT'
  AND cp_catalog_page_number >= 10
ORDER BY cp_catalog_page_number * 2 DESC, cp_catalog_page_id
LIMIT 100
