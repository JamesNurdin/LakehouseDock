SELECT cs.cs_order_number,
       cs.cs_sales_price,
       t.t_hour
FROM   tpcds.catalog_sales cs
JOIN   tpcds.time_dim t
       ON cs.cs_sold_time_sk = t.t_time_sk
WHERE  cs.cs_sales_price > 30.00
  AND  t.t_hour BETWEEN 8 AND 12
