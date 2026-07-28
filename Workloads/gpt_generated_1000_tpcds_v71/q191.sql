SELECT
  d_month_seq,
  COUNT(DISTINCT d_date) AS unique_weekend_dates
FROM tpcds.date_dim
WHERE d_weekend = 'Y'
  AND d_fy_week_seq IN (5, 7)
GROUP BY d_month_seq
ORDER BY d_month_seq
LIMIT 100
