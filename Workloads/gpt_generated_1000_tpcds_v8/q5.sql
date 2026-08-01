SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_gmt_offset,
    d.d_year,
    d.d_month_seq
FROM tpcds.call_center AS cc
JOIN tpcds.date_dim AS d
  ON cc.cc_closed_date_sk = d.d_date_sk
WHERE d.d_year = 1915
  AND cc.cc_gmt_offset = -6.00
ORDER BY cc.cc_name
LIMIT 100
