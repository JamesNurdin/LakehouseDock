SELECT DISTINCT
    t_time_id,
    t_hour,
    t_minute,
    t_meal_time
FROM tpcds.time_dim
WHERE t_hour IN (9, 13, 19)
  AND t_minute >= 6
ORDER BY t_hour ASC, t_minute DESC
LIMIT 100
