SELECT
  cc.cc_city,
  cc.cc_class,
  COUNT(*) AS call_center_cnt,
  AVG(cc.cc_employees) AS avg_employees
FROM tpcds.call_center AS cc
WHERE cc.cc_class = 'large'
  AND cc.cc_rec_start_date >= DATE '2000-01-01'
GROUP BY cc.cc_city, cc.cc_class
ORDER BY call_center_cnt DESC
