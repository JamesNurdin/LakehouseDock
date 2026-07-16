SELECT cs.cs_item_sk, sum(cs.cs_ext_sales_price) AS total_sales
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 1998
GROUP BY cs.cs_item_sk
ORDER BY total_sales DESC
LIMIT 10
