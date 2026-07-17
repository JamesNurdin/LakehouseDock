SELECT d.d_year,
       sum(cs.cs_net_paid) AS total_net_paid
FROM catalog_sales cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
WHERE cs.cs_sales_price > 50.0
  AND cs.cs_quantity >= 2
  AND cs.cs_ext_ship_cost < 2000.0
  AND d.d_date >= DATE '1998-01-01'
  AND d.d_date < DATE '1999-01-01'
GROUP BY d.d_year
