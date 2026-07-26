SELECT d.d_year,
       cs.cs_item_sk,
       COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
       SUM(cs.cs_quantity) AS total_sales_qty,
       SUM(cs.cs_net_profit) AS total_profit,
       AVG(t.t_hour) FILTER (WHERE t.t_hour BETWEEN 9 AND 17) AS avg_business_hour,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rownum
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
LEFT JOIN store_returns sr ON cs.cs_item_sk = sr.sr_item_sk AND cs.cs_sold_date_sk = sr.sr_returned_date_sk
WHERE cs.cs_quantity > 0
GROUP BY d.d_year, cs.cs_item_sk
ORDER BY total_profit DESC
LIMIT 50
