SELECT
    time_dim.t_hour,
    time_dim.t_shift,
    SUM(catalog_sales.cs_ext_sales_price) AS total_sales,
    SUM(catalog_sales.cs_net_profit) AS total_profit,
    AVG(catalog_sales.cs_ext_discount_amt) AS avg_discount,
    COUNT(*) AS transaction_count
FROM catalog_sales
JOIN time_dim
  ON catalog_sales.cs_sold_time_sk = time_dim.t_time_sk
WHERE catalog_sales.cs_quantity > 0
GROUP BY time_dim.t_hour, time_dim.t_shift
HAVING SUM(catalog_sales.cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 10
