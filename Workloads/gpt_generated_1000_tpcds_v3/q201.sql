SELECT cp_catalog_page_id,
       cp_catalog_number,
       COUNT(*) AS page_count
FROM tpcds.catalog_page
WHERE cp_catalog_number > 10
  AND cp_catalog_page_id LIKE 'AAAAAAA%'
GROUP BY cp_catalog_page_id, cp_catalog_number
ORDER BY page_count DESC, cp_catalog_page_id
