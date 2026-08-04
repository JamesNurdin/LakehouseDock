SELECT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    d.d_date
FROM tpcds.catalog_sales AS cs
JOIN tpcds.date_dim AS d
  ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_dom = 12
  AND cs.cs_ext_wholesale_cost > 2000.00
ORDER BY cs.cs_order_number
LIMIT 100
