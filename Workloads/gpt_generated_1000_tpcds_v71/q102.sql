SELECT td.t_hour,
       td.t_meal_time,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       COUNT(DISTINCT cs.cs_order_number) AS orders_count
FROM catalog_sales cs
JOIN time_dim td
  ON cs.cs_sold_time_sk = td.t_time_sk
WHERE cs.cs_ext_ship_cost >= 1000
  AND td.t_meal_time = 'lunch'
GROUP BY td.t_hour, td.t_meal_time
ORDER BY total_sales DESC
LIMIT 100
