SELECT t_hour,
       COUNT(*) AS hour_count,
       AVG(t_second) AS avg_second
FROM time_dim
WHERE t_hour IN (4, 17, 18)
  AND t_time >= 5
GROUP BY t_hour
ORDER BY t_hour ASC
LIMIT 100
