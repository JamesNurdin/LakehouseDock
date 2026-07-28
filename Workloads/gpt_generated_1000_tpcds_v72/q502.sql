SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    d.d_date AS open_date,
    cc.cc_employees,
    cc.cc_sq_ft
FROM call_center AS cc
JOIN date_dim AS d
  ON cc.cc_open_date_sk = d.d_date_sk
WHERE d.d_week_seq = 8
  AND cc.cc_street_number = '759'
ORDER BY cc.cc_call_center_id
LIMIT 100
