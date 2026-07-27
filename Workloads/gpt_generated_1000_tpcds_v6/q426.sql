WITH catalog_part AS (
    SELECT
        i.i_item_id AS item_id,
        w.w_warehouse_name AS warehouse_name,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_net_profit AS net_profit,
        p.p_promo_name AS promo_name,
        (SELECT sum(p2.p_cost) FROM promotion p2 WHERE p2.p_promo_sk = cs.cs_promo_sk) AS total_promo_cost
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_quantity > 1
      AND p.p_channel_press = 'N'
      AND EXISTS (
            SELECT 1
            FROM inventory inv
            WHERE inv.inv_item_sk = cs.cs_item_sk
              AND inv.inv_warehouse_sk = cs.cs_warehouse_sk
              AND inv.inv_quantity_on_hand > 500
        )
),
web_part AS (
    SELECT
        i.i_item_id AS item_id,
        w.w_warehouse_name AS warehouse_name,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_net_profit AS net_profit,
        p.p_promo_name AS promo_name,
        (SELECT sum(p2.p_cost) FROM promotion p2 WHERE p2.p_promo_sk = ws.ws_promo_sk) AS total_promo_cost
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_quantity > 1
      AND p.p_channel_press = 'N'
      AND EXISTS (
            SELECT 1
            FROM inventory inv
            WHERE inv.inv_item_sk = ws.ws_item_sk
              AND inv.inv_warehouse_sk = ws.ws_warehouse_sk
              AND inv.inv_quantity_on_hand > 500
        )
)
SELECT
    item_id,
    warehouse_name,
    sold_date_sk,
    net_profit,
    promo_name,
    total_promo_cost
FROM catalog_part
UNION ALL
SELECT
    item_id,
    warehouse_name,
    sold_date_sk,
    net_profit,
    promo_name,
    total_promo_cost
FROM web_part
ORDER BY net_profit DESC, item_id
LIMIT 100
