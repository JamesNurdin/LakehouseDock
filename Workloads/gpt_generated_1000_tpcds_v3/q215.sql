SELECT w_warehouse_id,
       w_warehouse_name,
       w_warehouse_sq_ft,
       w_street_name,
       w_county
FROM tpcds.warehouse
WHERE w_street_name = 'Ash Center'
  AND w_county = 'Fairfield County'
ORDER BY w_warehouse_sq_ft DESC
LIMIT 100
