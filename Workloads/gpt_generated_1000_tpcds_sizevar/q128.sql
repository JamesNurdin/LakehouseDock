SELECT td.t_meal_time,
       SUM(ws.ws_ext_sales_price) AS total_sales
FROM web_sales ws
JOIN time_dim td
  ON ws.ws_sold_time_sk = td.t_time_sk
WHERE ws.ws_sales_price > 50
  AND td.t_second < 15
GROUP BY td.t_meal_time
ORDER BY total_sales DESC
