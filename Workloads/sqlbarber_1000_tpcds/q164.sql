SELECT sr.sr_store_sk,
       sr.sr_return_quantity,
       sr.sr_return_amt,
       sr.sr_return_amt * sr.sr_return_quantity AS total_return_value,
       CASE
         WHEN sr.sr_return_amt > 61.81 THEN 'high'
         WHEN sr.sr_return_amt > 350.40 THEN 'medium'
         ELSE 'low'
       END AS return_amount_category,
       (sr.sr_return_amt_inc_tax - sr.sr_return_tax) AS net_return_excluding_tax,
       t.t_hour,
       t.t_meal_time,
       CASE t.t_meal_time
         WHEN 'Breakfast' THEN 1
         WHEN 'Lunch' THEN 2
         WHEN 'Dinner' THEN 3
         ELSE 0
       END AS meal_time_code,
       (sr.sr_fee + sr.sr_return_ship_cost) * 0.1 AS fee_ship_cost_10pct
FROM store_returns sr
INNER JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
WHERE sr.sr_return_quantity > 1
  AND t.t_hour BETWEEN 9 AND 2
