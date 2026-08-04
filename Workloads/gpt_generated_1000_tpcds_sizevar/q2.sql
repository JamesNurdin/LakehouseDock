SELECT
  cc.cc_name,
  cc.cc_city,
  d.d_date AS open_date
FROM tpcds.call_center AS cc
JOIN tpcds.date_dim AS d
  ON cc.cc_open_date_sk = d.d_date_sk
WHERE d.d_current_month = 'Y'
  AND d.d_holiday = 'N'
  AND cc.cc_state = 'NY'
