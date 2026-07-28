WITH item_cte AS ( SELECT i_item_sk, i_category FROM item )
SELECT channel,
       year,
       month,
       total_net_paid,
       sales_level
FROM (
    SELECT 'Catalog' AS channel,
           d.d_year AS year,
           d.d_month_seq AS month,
           SUM(cs.cs_net_paid) AS total_net_paid,
           CASE WHEN SUM(cs.cs_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS sales_level
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item_cte ic ON cs.cs_item_sk = ic.i_item_sk
    WHERE d.d_year = 2001
      AND ic.i_category = 'Sports'
    GROUP BY d.d_year, d.d_month_seq
    UNION ALL
    SELECT 'Web' AS channel,
           d.d_year AS year,
           d.d_month_seq AS month,
           SUM(ws.ws_net_paid) AS total_net_paid,
           CASE WHEN SUM(ws.ws_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS sales_level
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item_cte ic ON ws.ws_item_sk = ic.i_item_sk
    WHERE d.d_year = 2001
      AND ic.i_category = 'Sports'
    GROUP BY d.d_year, d.d_month_seq
) AS combined
ORDER BY year, month, channel
LIMIT 100
