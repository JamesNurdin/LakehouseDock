SELECT s.s_city,
       d.d_date,
       d.d_holiday,
       COUNT(*) AS closed_store_count
FROM   store s
JOIN   date_dim d ON s.s_closed_date_sk = d.d_date_sk
WHERE  d.d_holiday = 'Y'
  AND  d.d_fy_week_seq = 9
GROUP BY s.s_city, d.d_date, d.d_holiday
ORDER BY closed_store_count DESC, s.s_city
LIMIT 100
