-- goal: List the top 100 items by net revenue in 2001 from catalog and web channels, excluding any items that were returned, and indicate the sales channel.
WITH sales_2001 AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
)
SELECT i_item_id,
       total_net_paid,
       sales_channel
FROM (
    SELECT i.i_item_id,
           SUM(cs.cs_net_paid) AS total_net_paid,
           'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN sales_2001 d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = cs.cs_order_number
          AND cr.cr_item_sk = cs.cs_item_sk
    )
    GROUP BY i.i_item_id

    UNION ALL

    SELECT i.i_item_id,
           SUM(ws.ws_net_paid) AS total_net_paid,
           'web' AS sales_channel
    FROM web_sales ws
    JOIN sales_2001 d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND wr.wr_item_sk = ws.ws_item_sk
    )
    GROUP BY i.i_item_id
) combined
ORDER BY total_net_paid DESC
LIMIT 100
