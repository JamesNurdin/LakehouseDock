SELECT
  cs.cs_order_number,
  cs.cs_ext_sales_price,
  cs.cs_ext_discount_amt,
  t.t_hour,
  t.t_minute
FROM catalog_sales AS cs
JOIN time_dim AS t
  ON cs.cs_sold_time_sk = t.t_time_sk
WHERE t.t_hour IN (8, 13)
  AND cs.cs_ext_sales_price > 5000
LIMIT 100
