SELECT
    w_warehouse_id,
    w_warehouse_name,
    w_city,
    w_state,
    w_gmt_offset
FROM tpcds.warehouse
WHERE w_street_name IN ('Ash Laurel', 'Ridge')
  AND w_suite_number = 'Suite 160'
