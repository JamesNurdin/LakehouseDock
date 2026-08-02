WITH inventory_agg AS (
    SELECT w.w_warehouse_id AS warehouse_id,
           i.inv_item_sk AS item_sk,
           SUM(i.inv_quantity_on_hand) AS total_qty
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand > 0
    GROUP BY w.w_warehouse_id, i.inv_item_sk
),
sales_agg AS (
    SELECT w.w_warehouse_id AS warehouse_id,
           ws.ws_item_sk AS item_sk,
           SUM(ws.ws_net_paid_inc_ship) AS total_sales,
           AVG(ws.ws_sales_price) AS avg_price
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_net_paid_inc_ship > 1000
    GROUP BY w.w_warehouse_id, ws.ws_item_sk
),
intersect_keys AS (
    SELECT warehouse_id, item_sk FROM inventory_agg
    INTERSECT
    SELECT warehouse_id, item_sk FROM sales_agg
)
SELECT i.warehouse_id,
       i.item_sk,
       i.total_qty,
       s.total_sales,
       s.avg_price
FROM intersect_keys ik
JOIN inventory_agg i ON ik.warehouse_id = i.warehouse_id AND ik.item_sk = i.item_sk
JOIN sales_agg s ON ik.warehouse_id = s.warehouse_id AND ik.item_sk = s.item_sk
ORDER BY i.warehouse_id, i.item_sk
LIMIT 100
