SELECT
    cc_state,
    COUNT(*) AS center_count,
    AVG(cc_employees) AS avg_employees
FROM tpcds.call_center
WHERE cc_class = 'large'
  AND cc_mkt_id IN (2, 3)
GROUP BY cc_state
ORDER BY center_count DESC
