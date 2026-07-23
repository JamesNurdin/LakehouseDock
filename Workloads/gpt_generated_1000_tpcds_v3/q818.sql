SELECT DISTINCT cp.cp_catalog_page_id,
                cp.cp_type,
                cp.cp_catalog_number,
                cr.cr_return_amount,
                cr.cr_return_ship_cost
FROM catalog_page cp
JOIN catalog_returns cr
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_type = 'monthly'
  AND cp.cp_catalog_number = 4
  AND cr.cr_return_ship_cost > 200
LIMIT 100
