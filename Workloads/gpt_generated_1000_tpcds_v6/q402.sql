SELECT
  cp.cp_catalog_page_id,
  cp.cp_department,
  d.d_date
FROM catalog_page AS cp
JOIN date_dim AS d
  ON cp.cp_end_date_sk = d.d_date_sk
WHERE d.d_current_quarter = 'Y'
  AND cp.cp_department = 'DEPARTMENT'
ORDER BY d.d_date DESC
LIMIT 100
