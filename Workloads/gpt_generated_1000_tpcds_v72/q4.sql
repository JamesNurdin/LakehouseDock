SELECT
    d_year,
    d_month_seq,
    COUNT(*) AS days_in_month
FROM tpcds.date_dim
WHERE d_current_quarter = 'Y'
  AND d_day_name = 'Monday'
GROUP BY d_year, d_month_seq
ORDER BY d_year, d_month_seq
