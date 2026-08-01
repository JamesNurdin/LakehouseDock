SELECT
    w_state,
    COUNT(DISTINCT w_warehouse_id) AS distinct_warehouses,
    MIN(w_gmt_offset) AS min_offset
FROM tpcds.warehouse
WHERE w_street_name IN ('Lincoln Adams', 'Spring')
  AND w_gmt_offset > -2.00
GROUP BY w_state
ORDER BY distinct_warehouses DESC, w_state
