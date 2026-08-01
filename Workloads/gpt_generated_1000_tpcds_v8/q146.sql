SELECT
    cp.cp_department,
    cp.cp_type,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_count
FROM catalog_page cp
JOIN catalog_returns cr
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_type = 'monthly'
  AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
GROUP BY cp.cp_department, cp.cp_type
ORDER BY total_return_amount DESC
LIMIT 100
