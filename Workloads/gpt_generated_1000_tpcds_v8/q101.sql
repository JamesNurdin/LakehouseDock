SELECT DISTINCT
  cc.cc_call_center_id,
  cc.cc_name,
  cc.cc_city,
  cc.cc_state
FROM tpcds.call_center AS cc
WHERE cc.cc_company_name = 'able'
  AND cc.cc_street_type = 'Avenue'
  AND cc.cc_rec_start_date >= DATE '2000-01-01'
