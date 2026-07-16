SELECT
    w.w_state,
    r.r_reason_desc,
    COUNT(*) AS reason_warehouse_pairs,
    SUM(CASE WHEN w.w_gmt_offset > 0 THEN 1 ELSE 0 END) AS pos_offset_cnt,
    AVG(w.w_warehouse_sq_ft) AS avg_sq_ft,
    ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY COUNT(*) DESC) AS rn
FROM
    reason r
JOIN
    warehouse w
    ON substr(r.r_reason_id, 1, 1) = substr(w.w_warehouse_id, 1, 1)
WHERE
    r.r_reason_desc IN ('Package was damaged', 'Stopped working', 'Did not get it on time')
    AND w.w_state IN ('NM', 'SD', 'OH')
GROUP BY
    w.w_state,
    r.r_reason_desc
HAVING
    COUNT(*) > 5
ORDER BY
    w.w_state,
    reason_warehouse_pairs DESC
LIMIT 100
