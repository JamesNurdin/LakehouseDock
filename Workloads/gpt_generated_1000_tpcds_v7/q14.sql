WITH recent_inventory AS (
    SELECT inv_item_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_date_sk = (
        SELECT MAX(d_date_sk)
        FROM date_dim
        WHERE d_year = 2002
    )
)
SELECT combined.i_item_id,
       combined.d_year,
       combined.total_sales,
       combined.channel
FROM (
    SELECT i.i_item_id,
           d.d_year,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           'catalog' AS channel,
           i.i_item_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY i.i_item_id, d.d_year, i.i_item_sk

    UNION ALL

    SELECT i.i_item_id,
           d.d_year,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           'web' AS channel,
           i.i_item_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY i.i_item_id, d.d_year, i.i_item_sk
) AS combined
WHERE NOT EXISTS (
    SELECT 1
    FROM recent_inventory ri
    WHERE ri.inv_item_sk = combined.i_item_sk
)
ORDER BY combined.total_sales DESC
LIMIT 100
