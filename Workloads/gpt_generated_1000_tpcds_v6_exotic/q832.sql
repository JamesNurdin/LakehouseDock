SELECT
    cp_department,
    cp_type,
    COUNT(DISTINCT cp_catalog_number) AS distinct_catalogs,
    COUNT(*) AS total_pages
FROM catalog_page
WHERE cp_catalog_number IN (6, 17)
  AND cp_description LIKE '%goods%'
GROUP BY cp_department, cp_type
ORDER BY cp_department, cp_type
