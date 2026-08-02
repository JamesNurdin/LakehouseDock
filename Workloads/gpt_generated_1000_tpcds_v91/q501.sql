SELECT t.t_meal_time, SUM(cr.cr_return_amount) AS total_return_amount
FROM catalog_returns cr
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
WHERE cr.cr_returned_date_sk = 2451086
GROUP BY t.t_meal_time
ORDER BY total_return_amount DESC
