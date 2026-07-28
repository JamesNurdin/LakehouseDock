WITH catalog_yearly AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
),
web_yearly AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
)
SELECT combined.i_item_id,
       combined.i_product_name,
       combined.channel,
       combined.total_net_paid
FROM (
    SELECT c.i_item_id,
           c.i_product_name,
           'catalog' AS channel,
           c.total_net_paid
    FROM catalog_yearly c
    UNION ALL
    SELECT w.i_item_id,
           w.i_product_name,
           'web' AS channel,
           w.total_net_paid
    FROM web_yearly w
) combined
ORDER BY combined.i_item_id,
         combined.channel
