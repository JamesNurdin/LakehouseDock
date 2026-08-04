SELECT
    w_state,
    COUNT(*) AS warehouse_cnt,
    AVG(w_gmt_offset) AS avg_offset
FROM tpcds.warehouse
WHERE w_street_type = 'Ave'
GROUP BY w_state
HAVING COUNT(*) > 1
ORDER BY warehouse_cnt DESC
