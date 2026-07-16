SELECT c.cs_sold_date_sk, SUM(c.cs_ext_sales_price) AS total_sales
FROM catalog_sales c
JOIN date_dim d ON c.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY c.cs_sold_date_sk
ORDER BY total_sales DESC
LIMIT 10
