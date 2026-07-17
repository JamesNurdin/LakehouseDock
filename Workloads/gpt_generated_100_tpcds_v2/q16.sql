SELECT d1.d_date AS sale_date,
       'Catalog' AS sales_channel,
       SUM(cs.cs_net_paid) AS total_net_paid
FROM catalog_sales cs
JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
WHERE d1.d_year = 2001
GROUP BY d1.d_date

UNION ALL

SELECT d2.d_date AS sale_date,
       'Web' AS sales_channel,
       SUM(ws.ws_net_paid) AS total_net_paid
FROM web_sales ws
JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
WHERE d2.d_year = 2001
GROUP BY d2.d_date
ORDER BY sale_date, sales_channel
