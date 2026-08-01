SELECT i.inv_item_sk,
       w.w_warehouse_name,
       SUM(i.inv_quantity_on_hand) AS total_quantity
FROM tpcds.inventory i
JOIN tpcds.warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.inv_quantity_on_hand > 200
  AND w.w_zip = '19231'
GROUP BY i.inv_item_sk, w.w_warehouse_name
ORDER BY total_quantity DESC
LIMIT 100
