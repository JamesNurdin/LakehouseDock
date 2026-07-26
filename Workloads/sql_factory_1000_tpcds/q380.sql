SELECT d_sold.d_date,
       COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
       SUM(cs.cs_quantity) AS total_quantity,
       SUM(cs.cs_net_paid) AS total_sales,
       AVG(cs.cs_net_profit) AS avg_profit_per_sale,
       COALESCE(SUM(sr.sr_return_amt_inc_tax),0) AS total_returns,
       SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid),0) AS profit_margin,
       RANK() OVER (ORDER BY SUM(cs.cs_quantity) DESC) AS quantity_rank,
       MAX(t_sold.t_hour) - MIN(t_sold.t_hour) AS sales_hour_range
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d_sold.d_date_sk AND sr.sr_item_sk = cs.cs_item_sk
WHERE cs.cs_quantity >= 5 AND d_sold.d_month_seq BETWEEN 1200 AND 1220
GROUP BY d_sold.d_date
HAVING SUM(cs.cs_net_paid) > 1000
ORDER BY profit_margin ASC
