SELECT sr.sr_store_sk,
       td.t_meal_time,
       SUM(sr.sr_return_amt) AS total_return_amount
FROM   store_returns sr
JOIN   time_dim td ON sr.sr_return_time_sk = td.t_time_sk
WHERE  td.t_meal_time = 'dinner'
  AND  td.t_time = 19
GROUP BY sr.sr_store_sk, td.t_meal_time
ORDER BY total_return_amount DESC
LIMIT 10
