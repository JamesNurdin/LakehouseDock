WITH inventory_agg AS (
    SELECT inv_warehouse_sk,
           inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_item_sk
),
union_sales AS (
    SELECT cs.cs_warehouse_sk AS wk,
           cs.cs_net_paid AS net_paid
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 20
    UNION ALL
    SELECT ws.ws_warehouse_sk,
           ws.ws_net_paid
    FROM web_sales ws
    WHERE ws.ws_quantity > 20
)
SELECT w.w_warehouse_name,
       sm_cs.sm_type AS ship_mode_type,
       COUNT(DISTINCT cs.cs_order_number) AS num_catalog_orders,
       SUM(cs.cs_net_paid) AS total_catalog_net_paid,
       SUM(CASE WHEN cr.cr_net_loss > 0 THEN cr.cr_net_loss ELSE 0 END) AS total_return_loss,
       COALESCE(inv_agg.total_qty, 0) AS total_inventory_qty,
       SUM(ws.ws_net_profit) AS total_web_profit,
       (
           SELECT MAX(cs2.cs_net_paid)
           FROM catalog_sales cs2
           WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
       ) AS max_catalog_net_paid_per_warehouse,
       SUM(us.net_paid) AS total_union_net_paid
FROM catalog_sales cs
JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory_agg inv_agg
       ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
      AND inv_agg.inv_item_sk = cs.cs_item_sk
JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN web_sales ws
     ON ws.ws_warehouse_sk = w.w_warehouse_sk
    AND ws.ws_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN union_sales us ON us.wk = w.w_warehouse_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = cs.cs_order_number
      AND cr2.cr_net_loss > 1000
)
GROUP BY w.w_warehouse_name,
         sm_cs.sm_type,
         w.w_warehouse_sk,
         inv_agg.total_qty
ORDER BY total_catalog_net_paid DESC
LIMIT 100
