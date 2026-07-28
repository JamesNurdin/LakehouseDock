SELECT DISTINCT
  t_meal_time,
  t_sub_shift,
  t_hour
FROM
  time_dim
WHERE
  t_sub_shift IN ('morning', 'afternoon')
  AND t_hour >= 6
ORDER BY
  t_meal_time,
  t_hour
LIMIT 100
