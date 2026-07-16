SELECT
    w.w_warehouse_name,
    sm.sm_type,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
    SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_quantity), 0) AS profit_per_item,
    RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
FROM inventory i
JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE i.inv_date_sk BETWEEN 2450900 AND 2451000
  AND ws.ws_sold_date_sk BETWEEN 2450900 AND 2451000
  AND sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
GROUP BY w.w_warehouse_name, sm.sm_type
HAVING SUM(ws.ws_net_profit) > 5000
ORDER BY total_net_profit DESC
LIMIT 50
