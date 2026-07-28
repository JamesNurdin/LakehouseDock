SELECT DISTINCT
  cp.cp_catalog_page_id,
  cp.cp_catalog_page_number,
  d.d_date
FROM catalog_page cp
JOIN date_dim d
  ON cp.cp_start_date_sk = d.d_date_sk
WHERE cp.cp_start_date_sk = 2451271
  AND d.d_moy = 10
ORDER BY cp.cp_catalog_page_id
LIMIT 100
