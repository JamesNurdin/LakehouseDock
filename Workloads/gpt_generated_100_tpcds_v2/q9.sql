SELECT w.w_warehouse_name,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_count
FROM tpcds.catalog_returns cr
JOIN tpcds.warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE cr.cr_returned_time_sk IN (39537, 55545)
  AND w.w_warehouse_sq_ft > 800000
GROUP BY w.w_warehouse_name
