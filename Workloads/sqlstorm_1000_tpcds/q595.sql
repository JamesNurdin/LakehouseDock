SELECT i.i_category, SUM(cs.cs_net_paid) AS total_sales
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY i.i_category
ORDER BY total_sales DESC
LIMIT 10
