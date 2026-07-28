SELECT cp.cp_catalog_page_id,
       cp.cp_description,
       d.d_date
FROM catalog_page cp
JOIN date_dim d ON cp.cp_end_date_sk = d.d_date_sk
WHERE d.d_last_dom = 2415567
  AND cp.cp_catalog_page_number = 10
LIMIT 100
