WITH avg_profit AS (
    SELECT AVG(profit) AS avg_profit
    FROM (
        SELECT cs_net_profit AS profit FROM catalog_sales
        UNION ALL
        SELECT ws_net_profit AS profit FROM web_sales
    ) AS combined_profits
),

catalog_agg AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        w.w_warehouse_id,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE 
            WHEN SUM(cs.cs_net_profit) > (SELECT avg_profit FROM avg_profit) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS profit_category,
        'Catalog' AS channel,
        latest_inv.latest_quantity
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN LATERAL (
        SELECT inv_quantity_on_hand AS latest_quantity
        FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
          AND inv.inv_warehouse_sk = w.w_warehouse_sk
        ORDER BY inv.inv_date_sk DESC
        LIMIT 1
    ) latest_inv
    WHERE NOT EXISTS (
            SELECT 1 FROM store_returns sr
            WHERE sr.sr_item_sk = i.i_item_sk
          )
      AND NOT EXISTS (
            SELECT 1 FROM web_returns wr
            WHERE wr.wr_item_sk = i.i_item_sk
          )
    GROUP BY i.i_item_id, i.i_product_name, w.w_warehouse_id, latest_inv.latest_quantity
),

web_agg AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE 
            WHEN SUM(ws.ws_net_profit) > (SELECT avg_profit FROM avg_profit) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS profit_category,
        'Web' AS channel,
        latest_inv.latest_quantity
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    CROSS JOIN LATERAL (
        SELECT inv_quantity_on_hand AS latest_quantity
        FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
          AND inv.inv_warehouse_sk = w.w_warehouse_sk
        ORDER BY inv.inv_date_sk DESC
        LIMIT 1
    ) latest_inv
    WHERE NOT EXISTS (
            SELECT 1 FROM store_returns sr
            WHERE sr.sr_item_sk = i.i_item_sk
          )
      AND NOT EXISTS (
            SELECT 1 FROM web_returns wr
            WHERE wr.wr_item_sk = i.i_item_sk
          )
    GROUP BY i.i_item_id, i.i_product_name, w.w_warehouse_id, latest_inv.latest_quantity
)

SELECT 
    i_item_id,
    i_product_name,
    w_warehouse_id,
    total_profit,
    profit_category,
    channel,
    latest_quantity
FROM catalog_agg
UNION ALL
SELECT 
    i_item_id,
    i_product_name,
    w_warehouse_id,
    total_profit,
    profit_category,
    channel,
    latest_quantity
FROM web_agg
ORDER BY total_profit DESC
LIMIT 100
