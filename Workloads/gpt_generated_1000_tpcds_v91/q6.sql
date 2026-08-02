SELECT td.t_shift,
       td.t_hour,
       SUM(ss.ss_net_profit) AS total_net_profit
FROM store_sales ss
JOIN time_dim td
  ON ss.ss_sold_time_sk = td.t_time_sk
WHERE td.t_shift = 'first               '
  AND ss.ss_sales_price > 50.0
GROUP BY td.t_shift, td.t_hour
ORDER BY total_net_profit DESC
