SELECT cs.cs_sold_date_sk,
       SUM(cs.cs_net_paid) AS total_net_paid,
       COUNT(*) AS order_count
FROM catalog_sales AS cs
GROUP BY cs.cs_sold_date_sk
ORDER BY total_net_paid DESC
LIMIT 10
