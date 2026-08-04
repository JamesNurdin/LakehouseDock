SELECT
    cc_call_center_id,
    cc_name,
    cc_employees,
    cc_country
FROM tpcds.call_center
WHERE cc_country = 'United States'
  AND cc_employees > 1000000
ORDER BY cc_employees DESC
LIMIT 10
