SELECT
    td.t_shift,
    td.t_hour,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 50000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
    (SELECT AVG(ss2.ss_wholesale_cost) FROM store_sales ss2) AS avg_wholesale_cost
FROM store_sales ss
JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
WHERE td.t_am_pm = 'AM'
  AND ss.ss_coupon_amt > 0
GROUP BY td.t_shift, td.t_hour

UNION ALL

SELECT
    td.t_shift,
    td.t_hour,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 50000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
    (SELECT AVG(ss2.ss_wholesale_cost) FROM store_sales ss2) AS avg_wholesale_cost
FROM store_sales ss
JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
WHERE td.t_am_pm = 'PM'
  AND ss.ss_coupon_amt > 0
GROUP BY td.t_shift, td.t_hour
ORDER BY t_shift, t_hour
LIMIT 100
