WITH ws_agg AS (
    SELECT 
        ws.ws_warehouse_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM tpcds.web_sales ws
    WHERE ws.ws_sales_price > 20
      AND ws.ws_quantity >= 2
      AND ws.ws_net_paid_inc_ship BETWEEN 500 AND 5000
    GROUP BY ws.ws_warehouse_sk, ws.ws_ship_mode_sk
), inv_agg AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items
    FROM tpcds.inventory inv
    WHERE inv.inv_quantity_on_hand BETWEEN 200 AND 800
    GROUP BY inv.inv_warehouse_sk
)
SELECT 
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_state,
    sm.sm_ship_mode_id,
    sm.sm_type,
    ws_agg.total_net_profit,
    ws_agg.total_quantity,
    inv_agg.total_inventory_qty,
    CASE WHEN ws_agg.total_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
    RANK() OVER (PARTITION BY w.w_state ORDER BY ws_agg.total_net_profit DESC) AS state_warehouse_rank,
    (SELECT AVG(ws2.ws_net_paid_inc_ship)
       FROM tpcds.web_sales ws2
      WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk) AS avg_net_paid_inc_ship_warehouse
FROM tpcds.warehouse w
INNER JOIN ws_agg
    ON w.w_warehouse_sk = ws_agg.ws_warehouse_sk
INNER JOIN tpcds.ship_mode sm
    ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN inv_agg
    ON w.w_warehouse_sk = inv_agg.inv_warehouse_sk
WHERE w.w_state IN ('CA', 'TX', 'NY', 'FL')
  AND sm.sm_type = 'AIR'
  AND w.w_gmt_offset BETWEEN -5.00 AND 5.00
ORDER BY ws_agg.total_net_profit DESC, w.w_warehouse_id
LIMIT 100
