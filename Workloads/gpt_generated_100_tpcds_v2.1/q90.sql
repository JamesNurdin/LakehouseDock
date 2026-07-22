SELECT td.t_shift,
       td.t_meal_time,
       SUM(wr.wr_return_amt) AS total_return_amount
FROM web_returns wr
JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
WHERE wr.wr_reason_sk = 16
  AND td.t_shift = 'second'
GROUP BY td.t_shift, td.t_meal_time
ORDER BY total_return_amount DESC
LIMIT 100
