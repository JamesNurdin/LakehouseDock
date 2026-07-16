SELECT i.i_brand, SUM(cs.cs_ext_sales_price) AS total_sales
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY i.i_brand
ORDER BY total_sales DESC
LIMIT 10
