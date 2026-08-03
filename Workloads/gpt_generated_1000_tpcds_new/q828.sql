SELECT w.w_warehouse_name,
       COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
       SUM(i.inv_quantity_on_hand) AS total_qty
FROM tpcds.inventory i
JOIN tpcds.warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.inv_warehouse_sk = 12
  AND i.inv_date_sk = 2451060
GROUP BY w.w_warehouse_name
ORDER BY total_qty DESC
LIMIT 10
