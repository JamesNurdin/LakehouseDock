SELECT
    COUNT(cc.cc_call_center_sk) AS num_centers,
    AVG(cc.cc_sq_ft) AS avg_sq_ft,
    MIN(cc.cc_rec_start_date) AS earliest_rec_start
FROM tpcds.call_center AS cc
JOIN tpcds.date_dim AS d
  ON cc.cc_open_date_sk = d.d_date_sk
WHERE d.d_year = 2000
  AND cc.cc_state = 'CA'
