SELECT
    cc_state,
    COUNT(*) AS center_count,
    AVG(cc_sq_ft) AS avg_sq_ft
FROM tpcds.call_center
WHERE cc_rec_end_date = DATE '2000-12-31'
  AND cc_division IN (2, 3)
GROUP BY cc_state
ORDER BY avg_sq_ft DESC
LIMIT 10
