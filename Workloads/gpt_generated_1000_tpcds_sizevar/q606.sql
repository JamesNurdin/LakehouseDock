SELECT
  w.w_warehouse_name,
  w.w_city,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(cr.cr_return_quantity) AS total_return_quantity,
  COUNT(*) AS return_count
FROM tpcds.catalog_returns AS cr
JOIN tpcds.warehouse AS w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE w.w_zip = '33604'
  AND cr.cr_reversed_charge > 50
GROUP BY w.w_warehouse_name, w.w_city
