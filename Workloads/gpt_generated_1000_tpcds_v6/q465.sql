SELECT
    time_dim.t_meal_time,
    COUNT(*) AS meal_count
FROM
    tpcds.time_dim
WHERE
    time_dim.t_second >= 5
    AND time_dim.t_meal_time IN ('breakfast', 'lunch')
GROUP BY
    time_dim.t_meal_time
ORDER BY
    meal_count DESC
