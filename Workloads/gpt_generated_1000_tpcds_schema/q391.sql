SELECT
    w.w_warehouse_name,
    w.w_city,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_qty
FROM catalog_returns cr
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE w.w_street_type = 'Avenue'
  AND cr.cr_return_amount > 100.00
GROUP BY w.w_warehouse_name, w.w_city
ORDER BY total_return_amount DESC
LIMIT 10
