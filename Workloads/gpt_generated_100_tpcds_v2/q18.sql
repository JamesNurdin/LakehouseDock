SELECT
    'Store-Warehouse' AS category,
    concat(s.s_store_name, ' - ', w.w_warehouse_name) AS description,
    s.s_state AS state
FROM tpcds.store s
JOIN tpcds.warehouse w
    ON s.s_state = w.w_state
WHERE s.s_number_employees > 100
  AND w.w_warehouse_sq_ft > 50000

UNION ALL

SELECT
    'Reason' AS category,
    r.r_reason_desc AS description,
    CAST(NULL AS varchar) AS state
FROM tpcds.reason r
WHERE r.r_reason_desc LIKE '%Package%'
