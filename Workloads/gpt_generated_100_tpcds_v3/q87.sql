SELECT cp.cp_catalog_page_id,
       cp.cp_type,
       d.d_date
FROM catalog_page cp
JOIN date_dim d
  ON cp.cp_start_date_sk = d.d_date_sk
WHERE cp.cp_type = 'monthly'
  AND d.d_current_month = 'Y'
ORDER BY cp.cp_catalog_page_id
LIMIT 100
