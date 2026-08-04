SELECT cp.cp_department,
       COUNT(*) AS page_count
FROM catalog_page cp
JOIN date_dim d
  ON cp.cp_start_date_sk = d.d_date_sk
WHERE cp.cp_start_date_sk IN (2451210, 2451025)
  AND d.d_dow = 5
GROUP BY cp.cp_department
ORDER BY page_count DESC
