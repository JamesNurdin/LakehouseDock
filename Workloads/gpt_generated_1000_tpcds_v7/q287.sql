SELECT
  w_state,
  COUNT(*) AS warehouse_cnt,
  AVG(w_gmt_offset) AS avg_offset
FROM tpcds.warehouse
WHERE w_street_type = 'Avenue'
  AND w_street_number = '288'
GROUP BY w_state
ORDER BY warehouse_cnt DESC
