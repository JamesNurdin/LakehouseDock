SELECT d.d_year,
       cs.cs_item_sk,
       SUM(cs.cs_quantity) AS total_qty,
       SUM(cs.cs_net_paid) AS total_paid,
       COALESCE(SUM(sr.sr_return_quantity), 0) AS returned_qty,
       SUM(cs.cs_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_profit,
       RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank,
       MIN(t.t_hour) AS first_sale_hour
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
LEFT JOIN store_returns sr ON cs.cs_item_sk = sr.sr_item_sk AND cs.cs_sold_date_sk = sr.sr_returned_date_sk
GROUP BY d.d_year, cs.cs_item_sk
HAVING SUM(cs.cs_net_profit) > 0 AND SUM(cs.cs_quantity) > 5
ORDER BY d.d_year, profit_rank
