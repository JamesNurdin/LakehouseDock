SELECT DISTINCT d.d_date,
                d.d_day_name,
                s.ss_net_paid,
                s.ss_ext_sales_price
FROM   store_sales s
JOIN   date_dim d ON s.ss_sold_date_sk = d.d_date_sk
WHERE  d.d_fy_week_seq = 14
  AND  s.ss_ext_wholesale_cost > 2000
ORDER BY d.d_date DESC
LIMIT 100
