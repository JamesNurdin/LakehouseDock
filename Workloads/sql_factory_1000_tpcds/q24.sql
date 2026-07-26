SELECT d.d_year,
       cs.cs_item_sk,
       SUM(cs.cs_quantity) AS total_sales_qty,
       COALESCE(SUM(sr.sr_return_quantity), 0) AS total_return_qty,
       SUM(cs.cs_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_profit_after_returns,
       CASE WHEN SUM(cs.cs_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) > 15000 THEN 'VERY HIGH'
            WHEN SUM(cs.cs_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) > 8000 THEN 'HIGH'
            WHEN SUM(cs.cs_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) > 3000 THEN 'MEDIUM'
            ELSE 'LOW' END AS profit_category,
       RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) DESC) AS profit_rank_in_year,
       MIN(t.t_hour) AS earliest_sale_hour
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
LEFT JOIN store_returns sr ON cs.cs_item_sk = sr.sr_item_sk AND cs.cs_sold_date_sk = sr.sr_returned_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY d.d_year, cs.cs_item_sk
HAVING SUM(cs.cs_quantity) > 1000
ORDER BY d.d_year DESC, profit_rank_in_year
