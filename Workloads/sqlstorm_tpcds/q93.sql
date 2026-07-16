SELECT cs.cs_catalog_page_sk, sum(cs.cs_net_paid) AS total_sales
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2000
GROUP BY cs.cs_catalog_page_sk
ORDER BY total_sales DESC
LIMIT 5
