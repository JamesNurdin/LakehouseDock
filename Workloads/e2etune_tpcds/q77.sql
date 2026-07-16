SELECT w.w_warehouse_id,
       w.w_city,
       sm.sm_type,
       SUM(ws.ws_net_profit) AS total_net_profit,
       SUM(ws.ws_quantity) AS total_quantity_sold,
       inv_stats.avg_inv_qty AS avg_inventory_on_hand
FROM web_sales ws
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN (
    SELECT inv_warehouse_sk, AVG(inv_quantity_on_hand) AS avg_inv_qty
    FROM inventory
    WHERE inv_date_sk BETWEEN 2450900 AND 2451100
    GROUP BY inv_warehouse_sk
) inv_stats ON w.w_warehouse_sk = inv_stats.inv_warehouse_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450900 AND 2451100
  AND sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
  AND w.w_state = 'CA'
GROUP BY w.w_warehouse_id, w.w_city, sm.sm_type, inv_stats.avg_inv_qty
HAVING SUM(ws.ws_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 10
