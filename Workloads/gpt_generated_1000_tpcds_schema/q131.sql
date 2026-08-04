SELECT
  cc_city,
  cc_state,
  COUNT(*) AS cnt,
  AVG(cc_employees) AS avg_employees
FROM tpcds.call_center
WHERE cc_rec_start_date >= DATE '2000-01-01'
  AND cc_street_type = 'Avenue'
GROUP BY cc_city, cc_state
ORDER BY cnt DESC
LIMIT 10
