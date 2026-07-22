SELECT cc_call_center_id,
       cc_name,
       cc_city,
       cc_state,
       cc_employees
FROM tpcds.call_center
WHERE cc_county = 'Maverick County'
  AND cc_employees > 1000000
ORDER BY cc_employees DESC
LIMIT 100
