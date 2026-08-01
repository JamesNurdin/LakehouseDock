WITH
    full_sales AS (
        SELECT
            ws.ws_order_number,
            w.w_warehouse_id,
            w.w_state,
            td.t_hour,
            sm.sm_type,
            sm.sm_contract,
            ws.ws_quantity,
            ws.ws_net_profit,
            ws.ws_ext_wholesale_cost,
            inv.inv_quantity_on_hand
        FROM web_sales ws
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE
            td.t_hour BETWEEN 9 AND 17
            AND sm.sm_type = 'OVERNIGHT'
            AND w.w_state = 'CA'
            AND ws.ws_ext_wholesale_cost > 2000
            AND ws.ws_quantity >= 1
            AND sm.sm_contract = 'Ek'
    ),
    warehouse_agg AS (
        SELECT
            w_warehouse_id,
            SUM(ws_net_profit) AS total_net_profit,
            SUM(ws_quantity) AS total_quantity,
            COUNT(DISTINCT ws_order_number) AS order_cnt
        FROM full_sales
        GROUP BY w_warehouse_id
    ),
    inventory_agg AS (
        SELECT
            w.w_warehouse_id,
            SUM(inv.inv_quantity_on_hand) AS total_on_hand,
            AVG(inv.inv_quantity_on_hand) AS avg_on_hand
        FROM inventory inv
        JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
        GROUP BY w.w_warehouse_id
    ),
    high_profit AS (
        SELECT w_warehouse_id
        FROM warehouse_agg
        WHERE total_net_profit > 20000
    ),
    high_inventory AS (
        SELECT w_warehouse_id
        FROM inventory_agg
        WHERE total_on_hand > 10000
    ),
    intersect_warehouses AS (
        SELECT w_warehouse_id
        FROM high_profit
        INTERSECT
        SELECT w_warehouse_id
        FROM high_inventory
    )
SELECT
    wa.w_warehouse_id,
    wa.total_net_profit,
    wa.total_quantity,
    ia.total_on_hand,
    wa.total_net_profit / NULLIF(ia.total_on_hand, 0) AS profit_per_onhand
FROM warehouse_agg wa
JOIN inventory_agg ia ON wa.w_warehouse_id = ia.w_warehouse_id
WHERE wa.w_warehouse_id IN (SELECT w_warehouse_id FROM intersect_warehouses)
ORDER BY profit_per_onhand DESC
LIMIT 10
