SELECT d_date,
       d_day_name,
       d_quarter_name,
       COUNT(*) AS cnt
FROM   tpcds.date_dim
WHERE  d_quarter_name = '1902Q3'
  AND  d_fy_week_seq BETWEEN 10 AND 20
GROUP BY d_date, d_day_name, d_quarter_name
ORDER BY cnt DESC
LIMIT 10
