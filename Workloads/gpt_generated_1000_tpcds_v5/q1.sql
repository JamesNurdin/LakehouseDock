SELECT d_day_name,
       COUNT(*) AS days_in_month
FROM tpcds.date_dim
WHERE d_holiday = 'Y'
  AND d_current_month = 'Y'
GROUP BY d_day_name
ORDER BY days_in_month DESC
