SELECT
  call_center.cc_state,
  COUNT(*) AS num_call_centers
FROM
  tpcds.call_center AS call_center
JOIN
  tpcds.date_dim AS date_dim
  ON call_center.cc_open_date_sk = date_dim.d_date_sk
WHERE
  date_dim.d_year = 2001
  AND call_center.cc_state = 'CA'
GROUP BY
  call_center.cc_state
