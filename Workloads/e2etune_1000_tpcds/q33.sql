WITH item_totals AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty_per_item
    FROM inventory
    WHERE inv_date_sk = 2451046
    GROUP BY inv_item_sk
),
warehouse_stats AS (
    SELECT inv_warehouse_sk,
           AVG(inv_quantity_on_hand) AS avg_qty_per_warehouse,
           SUM(inv_quantity_on_hand) AS total_qty_per_warehouse
    FROM inventory
    WHERE inv_date_sk = 2451046
    GROUP BY inv_warehouse_sk
)
SELECT i.inv_warehouse_sk,
       i.inv_item_sk,
       i.inv_quantity_on_hand,
       ws.avg_qty_per_warehouse,
       ws.total_qty_per_warehouse,
       it.total_qty_per_item,
       (i.inv_quantity_on_hand * 100.0 / it.total_qty_per_item) AS pct_of_item_total
FROM inventory i
JOIN item_totals it
  ON i.inv_item_sk = it.inv_item_sk
JOIN warehouse_stats ws
  ON i.inv_warehouse_sk = ws.inv_warehouse_sk
WHERE i.inv_date_sk = 2451046
  AND i.inv_warehouse_sk IN (15, 1, 9, 10, 16)
  AND i.inv_item_sk IN (1, 2, 4, 7, 8)
  AND i.inv_quantity_on_hand > ws.avg_qty_per_warehouse
ORDER BY ws.total_qty_per_warehouse DESC,
         pct_of_item_total DESC
LIMIT 50
