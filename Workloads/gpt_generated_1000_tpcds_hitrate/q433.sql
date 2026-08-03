SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    cc.cc_zip
FROM tpcds.call_center AS cc
WHERE cc.cc_zip = '41933'
  AND cc.cc_suite_number = 'Suite B'
ORDER BY cc.cc_call_center_id
LIMIT 10
