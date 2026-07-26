SELECT d.d_year,
       cs.cs_item_sk,
       COUNT(*) AS sales_transactions,
       SUM(cs.cs_quantity) AS total_qty_sold,
       COALESCE(SUM(sr.sr_return_quantity), 0) AS total_qty_returned,
       AVG(cs.cs_net_profit) AS avg_profit_per_sale,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_quantity) DESC) AS qty_rank,
       MIN(t.t_hour) AS earliest_sale_hour
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
LEFT JOIN store_returns sr ON cs.cs_item_sk = sr.sr_item_sk AND cs.cs_sold_date_sk = sr.sr_returned_date_sk
WHERE cs.cs_list_price > 0
GROUP BY d.d_year, cs.cs_item_sk
HAVING SUM(cs.cs_quantity) > 10
ORDER BY d.d_year DESC, qty_rank
