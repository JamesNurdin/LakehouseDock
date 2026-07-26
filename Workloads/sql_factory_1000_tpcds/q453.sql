SELECT d_sold.d_date,
       SUM(cs.cs_net_paid) AS total_sales,
       SUM(cs.cs_net_profit) AS total_profit,
       COALESCE(SUM(sr.sr_return_amt_inc_tax), 0) AS total_returns,
       COALESCE(SUM(sr.sr_return_quantity), 0) AS total_return_qty,
       CASE WHEN SUM(cs.cs_net_paid) = 0 THEN 0 ELSE SUM(cs.cs_net_profit) / SUM(cs.cs_net_paid) END AS profit_margin,
       RANK() OVER (PARTITION BY d_sold.d_day_name ORDER BY SUM(cs.cs_net_profit) DESC) AS daily_profit_rank,
       MIN(t_sold.t_hour) AS first_sale_hour,
       MAX(t_sold.t_hour) AS last_sale_hour,
       SUM(cs.cs_quantity) FILTER (WHERE cs.cs_wholesale_cost > 50) AS high_wholesale_qty
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d_sold.d_date_sk AND sr.sr_item_sk = cs.cs_item_sk
WHERE d_sold.d_current_day = 'Y'
GROUP BY d_sold.d_date, d_sold.d_day_name
ORDER BY total_sales DESC
