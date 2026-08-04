SELECT cp.cp_catalog_page_id,
       cp.cp_department,
       cp.cp_catalog_page_number
FROM tpcds.catalog_page AS cp
WHERE cp.cp_department = 'DEPARTMENT'
  AND cp.cp_catalog_page_number IN (10, 12, 19)
ORDER BY cp.cp_catalog_page_number
