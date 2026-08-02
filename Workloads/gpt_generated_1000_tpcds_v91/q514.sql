SELECT cp.cp_catalog_page_id,
       cp.cp_catalog_page_number,
       d.d_date,
       d.d_holiday
FROM catalog_page cp
JOIN date_dim d
  ON cp.cp_end_date_sk = d.d_date_sk
WHERE cp.cp_end_date_sk = 2451543
  AND d.d_following_holiday = 'N'
ORDER BY cp.cp_catalog_page_number ASC
LIMIT 100
