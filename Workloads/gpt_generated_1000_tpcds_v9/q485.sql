WITH channel_sales AS (
    SELECT i.i_category AS category,
           'catalog' AS channel,
           SUM(cs.cs_net_paid) AS net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category
    UNION ALL
    SELECT i.i_category AS category,
           'web' AS channel,
           SUM(ws.ws_net_paid) AS net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category
)
SELECT category,
       SUM(net_paid) AS total_net_paid
FROM channel_sales
GROUP BY category
ORDER BY total_net_paid DESC
LIMIT 100
