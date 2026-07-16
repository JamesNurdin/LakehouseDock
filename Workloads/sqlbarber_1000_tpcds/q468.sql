SELECT time_dim.t_hour,
       SUM(store_sales.ss_ext_sales_price) AS total_store_sales,
       SUM(web_sales.ws_ext_sales_price) AS total_web_sales
FROM store_sales
JOIN time_dim ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
JOIN web_sales ON web_sales.ws_sold_time_sk = time_dim.t_time_sk
WHERE time_dim.t_hour = 19
  AND time_dim.t_meal_time = 'dinner              '
GROUP BY time_dim.t_hour
ORDER BY total_store_sales DESC
LIMIT 100
