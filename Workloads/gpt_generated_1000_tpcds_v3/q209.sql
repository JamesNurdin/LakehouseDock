SELECT cc_state,
       COUNT(*) AS num_centers,
       AVG(cc_employees) AS avg_employees,
       AVG(cc_sq_ft) AS avg_sq_ft
FROM tpcds.call_center
WHERE cc_state = 'CA'
  AND cc_market_manager = 'Mark Camp'
GROUP BY cc_state
LIMIT 100
