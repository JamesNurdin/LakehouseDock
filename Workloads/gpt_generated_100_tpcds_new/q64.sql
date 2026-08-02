SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt
FROM catalog_returns cr
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_type = 'monthly'
  AND cr.cr_warehouse_sk = 2
GROUP BY cp.cp_catalog_page_id, cp.cp_type
ORDER BY total_return_amount DESC
LIMIT 10
