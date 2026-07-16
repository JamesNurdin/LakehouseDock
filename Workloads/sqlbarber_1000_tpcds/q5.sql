SELECT w.w_warehouse_name,
       SUM(cr.cr_return_amount) AS total_return_amount
FROM catalog_returns cr
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE cr.cr_returned_date_sk = 2450972
GROUP BY w.w_warehouse_name
