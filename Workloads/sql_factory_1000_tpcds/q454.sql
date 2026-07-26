SELECT d_sold.d_year,
       SUM(cs.cs_net_paid) AS total_sales,
       AVG(cs.cs_net_profit) AS avg_profit,
       COALESCE(SUM(sr.sr_return_amt_inc_tax), 0) AS total_returns,
       COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
       CASE WHEN SUM(cs.cs_net_paid) = 0 THEN 0 ELSE SUM(cs.cs_net_profit) / SUM(cs.cs_net_paid) END AS profit_margin,
       ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_net_paid) DESC) AS sales_rank,
       MAX(t_sold.t_hour) FILTER (WHERE t_sold.t_am_pm = 'PM') AS last_pm_sale_hour
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d_sold.d_date_sk AND sr.sr_item_sk = cs.cs_item_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2005
GROUP BY d_sold.d_year
ORDER BY total_sales DESC
