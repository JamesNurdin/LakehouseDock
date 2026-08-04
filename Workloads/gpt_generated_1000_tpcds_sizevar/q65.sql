SELECT cc_state,
       COUNT(*) AS center_count,
       AVG(cc_employees) AS avg_employees
FROM tpcds.call_center
WHERE cc_zip IN ('36787', '74593')
  AND cc_employees > 4000000
GROUP BY cc_state
ORDER BY avg_employees DESC
LIMIT 10
