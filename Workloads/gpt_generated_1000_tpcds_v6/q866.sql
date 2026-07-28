WITH cat_sales AS (
    SELECT
        i.i_item_id,
        i.i_item_sk,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
        'Catalog' AS sales_channel,
        (SELECT AVG(cs2.cs_net_profit)
         FROM catalog_sales cs2
         WHERE cs2.cs_item_sk = i.i_item_sk) AS avg_item_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
      AND NOT EXISTS (
            SELECT 1
            FROM inventory inv
            WHERE inv.inv_item_sk = cs.cs_item_sk
              AND inv.inv_warehouse_sk = cs.cs_warehouse_sk
        )
    GROUP BY i.i_item_id, i.i_item_sk, w.w_warehouse_name
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_sk,
        w.w_warehouse_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
        'Web' AS sales_channel,
        (SELECT AVG(ws2.ws_net_profit)
         FROM web_sales ws2
         WHERE ws2.ws_item_sk = i.i_item_sk) AS avg_item_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
      AND NOT EXISTS (
            SELECT 1
            FROM inventory inv
            WHERE inv.inv_item_sk = ws.ws_item_sk
              AND inv.inv_warehouse_sk = ws.ws_warehouse_sk
        )
    GROUP BY i.i_item_id, i.i_item_sk, w.w_warehouse_name
)
SELECT DISTINCT
    item_id,
    warehouse_name,
    total_net_profit,
    profit_category,
    sales_channel,
    avg_item_profit
FROM (
    SELECT i_item_id AS item_id,
           w_warehouse_name AS warehouse_name,
           total_net_profit,
           profit_category,
           sales_channel,
           avg_item_profit
    FROM cat_sales
    UNION ALL
    SELECT i_item_id AS item_id,
           w_warehouse_name AS warehouse_name,
           total_net_profit,
           profit_category,
           sales_channel,
           avg_item_profit
    FROM web_sales_agg
) combined
ORDER BY profit_category, total_net_profit DESC
LIMIT 100
