SELECT
    w.w_warehouse_name,
    w.w_city,
    cr.cr_return_amount,
    cr.cr_return_quantity
FROM catalog_returns cr
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE w.w_street_number = '600'
  AND cr.cr_store_credit > 20
LIMIT 100
