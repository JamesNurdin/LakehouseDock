SELECT cp_catalog_page_id,
       cp_type,
       cp_department,
       cp_catalog_page_number
FROM catalog_page
WHERE cp_type = 'monthly'
  AND cp_department = 'Electronics'
LIMIT 100
