SELECT
    w_state,
    COUNT(*) AS warehouse_count,
    AVG(w_warehouse_sq_ft) AS avg_sq_ft
FROM tpcds.warehouse
WHERE w_warehouse_sq_ft > 700000
  AND w_gmt_offset = -5.00
GROUP BY w_state
ORDER BY warehouse_count DESC
