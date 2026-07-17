SELECT cp.cp_catalog_page_id,
       cp.cp_department,
       SUM(cr.cr_return_amount) AS total_return_amount
FROM catalog_returns cr
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cr.cr_ship_mode_sk = 11
  AND cp.cp_catalog_number = 8
  AND cr.cr_store_credit > 10.0
GROUP BY cp.cp_catalog_page_id, cp.cp_department
