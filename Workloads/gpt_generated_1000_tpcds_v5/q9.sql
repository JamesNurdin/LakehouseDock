SELECT
    td.t_meal_time,
    COUNT(*) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_fee) AS avg_fee
FROM store_returns sr
JOIN time_dim td
  ON sr.sr_return_time_sk = td.t_time_sk
WHERE td.t_meal_time = 'lunch'
  AND sr.sr_fee > 20.00
GROUP BY td.t_meal_time
ORDER BY total_return_amount DESC
LIMIT 100
