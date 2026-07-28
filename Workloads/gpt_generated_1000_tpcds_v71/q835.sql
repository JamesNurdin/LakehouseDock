SELECT
  d_fy_week_seq,
  COUNT(*) AS date_cnt
FROM tpcds.date_dim
WHERE d_last_dom IN (2415139, 2415020)
  AND d_fy_week_seq = 5
GROUP BY d_fy_week_seq
ORDER BY d_fy_week_seq
LIMIT 100
