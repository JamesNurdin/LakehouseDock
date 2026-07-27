SELECT cp_catalog_page_id,
       cp_catalog_number,
       cp_description
FROM tpcds.catalog_page
WHERE cp_end_date_sk = 2451543
  AND cp_catalog_number IN (4, 8, 14)
ORDER BY cp_catalog_page_id
