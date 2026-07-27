SELECT
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity
FROM tpcds.catalog_page cp
JOIN tpcds.catalog_returns cr
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_catalog_number = 11
  AND cp.cp_end_date_sk = 2450905
  AND cr.cr_store_credit > 0
GROUP BY cp.cp_catalog_number, cp.cp_catalog_page_number
ORDER BY total_return_amount DESC
LIMIT 100
