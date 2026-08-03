SELECT
  cp.cp_catalog_page_id,
  cp.cp_catalog_number,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(cr.cr_return_quantity) AS total_return_quantity
FROM
  catalog_returns cr
JOIN
  catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
  cr.cr_return_tax > 10.00
  AND cp.cp_catalog_number = 13
GROUP BY
  cp.cp_catalog_page_id,
  cp.cp_catalog_number
HAVING
  SUM(cr.cr_return_amount) > 100.00
