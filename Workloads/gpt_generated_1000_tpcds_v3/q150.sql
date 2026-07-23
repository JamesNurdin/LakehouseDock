SELECT w.w_warehouse_id,
       w.w_warehouse_name,
       SUM(i.inv_quantity_on_hand) AS total_quantity
FROM inventory i
JOIN warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_warehouse_sq_ft > 500000
  AND i.inv_quantity_on_hand > 500
GROUP BY w.w_warehouse_id, w.w_warehouse_name
ORDER BY total_quantity DESC
LIMIT 100
