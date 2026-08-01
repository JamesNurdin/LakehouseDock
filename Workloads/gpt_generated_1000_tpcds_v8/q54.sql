SELECT
  d_date,
  d_day_name,
  d_holiday,
  d_current_month,
  d_same_day_ly
FROM tpcds.date_dim
WHERE d_current_month = 'Y'
  AND d_same_day_ly > 2414660
ORDER BY d_date DESC
LIMIT 100
