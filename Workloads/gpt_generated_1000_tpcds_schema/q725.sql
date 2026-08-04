SELECT t.t_am_pm,
       SUM(s.ss_net_paid) AS total_net_paid
FROM store_sales s
JOIN time_dim t
  ON s.ss_sold_time_sk = t.t_time_sk
WHERE t.t_am_pm = 'PM'
  AND s.ss_net_paid > 100
GROUP BY t.t_am_pm
