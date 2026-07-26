SELECT d.d_year,
       cs.cs_item_sk,
       SUM(cs.cs_quantity) AS qty_sold,
       SUM(cs.cs_ext_discount_amt) AS total_discount,
       COALESCE(SUM(sr.sr_return_quantity), 0) AS qty_returned,
       SUM(cs.cs_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_profit_adj,
       PERCENT_RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_quantity) DESC) AS qty_percentile,
       MAX(t.t_hour) AS max_sale_hour
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
LEFT JOIN store_returns sr ON cs.cs_item_sk = sr.sr_item_sk AND cs.cs_sold_date_sk = sr.sr_returned_date_sk
WHERE d.d_current_year = 'Y'
GROUP BY d.d_year, cs.cs_item_sk
HAVING SUM(cs.cs_quantity) >= 20
ORDER BY d.d_year, qty_percentile DESC
