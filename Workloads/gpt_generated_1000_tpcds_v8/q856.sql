SELECT
  cc.cc_call_center_id,
  cc.cc_name,
  cc.cc_state,
  cc.cc_zip,
  d.d_date AS open_date,
  d.d_day_name
FROM tpcds.call_center AS cc
JOIN tpcds.date_dim AS d
  ON cc.cc_open_date_sk = d.d_date_sk
WHERE d.d_current_year = 'Y'
  AND d.d_weekend = 'N'
ORDER BY cc.cc_call_center_id
LIMIT 100
