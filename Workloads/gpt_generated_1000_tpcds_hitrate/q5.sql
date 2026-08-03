SELECT
    w.w_warehouse_name,
    w.w_city,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS returns_count
FROM tpcds.catalog_returns cr
JOIN tpcds.warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE w.w_country = 'United States'
  AND cr.cr_call_center_sk IN (1, 14)
  AND cr.cr_return_amount > 100
GROUP BY w.w_warehouse_name, w.w_city
ORDER BY total_return_amount DESC
LIMIT 10
