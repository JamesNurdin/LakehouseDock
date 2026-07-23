SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    SUM(i.inv_quantity_on_hand) AS total_qty,
    AVG(i.inv_quantity_on_hand) AS avg_qty,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
    SUM(i.inv_quantity_on_hand) / (SELECT SUM(inv_quantity_on_hand) FROM inventory) AS pct_of_total_inventory,
    MIN(w.w_warehouse_sq_ft) AS warehouse_sq_ft
FROM inventory i
JOIN warehouse w
    ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.inv_item_sk IN (101434, 101446, 101413)
  AND i.inv_quantity_on_hand >= 300
  AND w.w_warehouse_sq_ft >= 800000
  AND w.w_suite_number = 'Suite 370'
GROUP BY w.w_warehouse_id, w.w_warehouse_name
ORDER BY total_qty DESC
LIMIT 100
