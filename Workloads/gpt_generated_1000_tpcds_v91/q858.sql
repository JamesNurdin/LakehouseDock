SELECT cr.cr_returned_date_sk,
       cr.cr_return_quantity,
       cr.cr_return_amount,
       cr.cr_store_credit,
       cp.cp_catalog_page_id,
       cp.cp_description
FROM catalog_returns cr
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_catalog_page_number = 21
  AND cr.cr_store_credit > 1000
ORDER BY cr.cr_return_amount DESC
LIMIT 100
