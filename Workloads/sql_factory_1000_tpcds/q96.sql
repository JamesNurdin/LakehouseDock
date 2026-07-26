SELECT d.d_year,
       cs.cs_item_sk,
       SUM(cs.cs_ext_sales_price) AS total_sales_amount,
       COALESCE(SUM(sr.sr_return_amt_inc_tax), 0) AS total_return_amount,
       SUM(cs.cs_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_profit_after_returns,
       NTILE(5) OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_decile,
       MAX(t.t_hour) FILTER (WHERE t.t_am_pm = 'PM') AS latest_pm_hour
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
LEFT JOIN store_returns sr ON cs.cs_item_sk = sr.sr_item_sk AND cs.cs_sold_date_sk = sr.sr_returned_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY d.d_year, cs.cs_item_sk
HAVING SUM(cs.cs_ext_sales_price) > 1000
ORDER BY d.d_year, sales_decile
