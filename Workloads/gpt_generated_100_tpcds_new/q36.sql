SELECT
  w.w_county,
  COUNT(*) AS warehouse_cnt,
  AVG(w.w_warehouse_sq_ft) AS avg_sq_ft
FROM tpcds.warehouse AS w
WHERE w.w_gmt_offset = -7.00
  AND w.w_warehouse_sq_ft > 500000
GROUP BY w.w_county
ORDER BY warehouse_cnt DESC
LIMIT 10
