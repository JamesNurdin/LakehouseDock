SELECT
  cp_department,
  COUNT(*) AS page_count,
  AVG(cp_catalog_page_number) AS avg_page_number
FROM
  catalog_page
WHERE
  cp_department = 'DEPARTMENT'
  AND cp_catalog_page_number > 15
GROUP BY
  cp_department
