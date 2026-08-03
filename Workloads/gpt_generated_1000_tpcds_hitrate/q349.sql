WITH agg_inventory AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    i.i_category,
    i.i_brand,
    sm.sm_carrier,
    ws.ws_order_number,
    agg_inventory.total_qty_on_hand,
    ws.ws_net_profit,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    (
        SELECT MAX(i2.i_current_price)
        FROM item i2
        WHERE i2.i_category = i.i_category
    ) AS max_category_price,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ws.ws_net_profit DESC) AS profit_rank
FROM web_sales ws
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse wh_ws
    ON ws.ws_warehouse_sk = wh_ws.w_warehouse_sk
JOIN agg_inventory
    ON agg_inventory.inv_item_sk = i.i_item_sk
JOIN warehouse wh_inv
    ON agg_inventory.inv_warehouse_sk = wh_inv.w_warehouse_sk
JOIN inventory inv2
    ON inv2.inv_item_sk = i.i_item_sk
   AND inv2.inv_warehouse_sk <> agg_inventory.inv_warehouse_sk
JOIN warehouse wh_inv2
    ON inv2.inv_warehouse_sk = wh_inv2.w_warehouse_sk
JOIN ship_mode sm2
    ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450941 AND 2451067
  AND wh_ws.w_gmt_offset = -5.00
GROUP BY
    i.i_category,
    i.i_brand,
    sm.sm_carrier,
    ws.ws_order_number,
    agg_inventory.total_qty_on_hand,
    ws.ws_net_profit,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END,
    (
        SELECT MAX(i2.i_current_price)
        FROM item i2
        WHERE i2.i_category = i.i_category
    )
ORDER BY ws.ws_net_profit DESC
LIMIT 100
