SELECT d.d_year,
       sum(cs.cs_net_profit) AS total_net_profit
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2000
  AND cs.cs_quantity > 5
  AND cs.cs_sales_price > 1000
GROUP BY d.d_year
