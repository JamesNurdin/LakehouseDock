SELECT
  cp_department,
  cp_catalog_number,
  COUNT(*) AS page_cnt
FROM tpcds.catalog_page
WHERE cp_catalog_number IN (12, 16)
  AND cp_department = 'DEPARTMENT'
GROUP BY cp_department, cp_catalog_number
ORDER BY page_cnt DESC
LIMIT 100
