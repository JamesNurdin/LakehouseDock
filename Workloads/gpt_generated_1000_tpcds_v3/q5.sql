SELECT combined.i_item_id,
       combined.i_item_desc,
       combined.sales_channel,
       combined.total_quantity,
       combined.total_net_profit
FROM (
    SELECT i.i_item_id,
           i.i_item_desc,
           'catalog' AS sales_channel,
           SUM(cs.cs_quantity) AS total_quantity,
           SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
    GROUP BY i.i_item_id, i.i_item_desc

    UNION ALL

    SELECT i.i_item_id,
           i.i_item_desc,
           'web' AS sales_channel,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
    GROUP BY i.i_item_id, i.i_item_desc
) AS combined
ORDER BY combined.total_net_profit DESC
LIMIT 100
