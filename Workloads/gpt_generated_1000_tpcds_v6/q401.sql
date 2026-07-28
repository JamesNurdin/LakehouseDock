SELECT w_warehouse_id,
       w_warehouse_name,
       w_city,
       w_state,
       w_zip,
       w_gmt_offset
FROM tpcds.warehouse
WHERE w_gmt_offset = -6.00
  AND w_city LIKE '%San%'
ORDER BY w_warehouse_name
LIMIT 100
