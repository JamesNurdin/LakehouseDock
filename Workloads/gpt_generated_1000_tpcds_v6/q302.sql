SELECT
    w.w_warehouse_id,
    w.w_city,
    SUM(i.inv_quantity_on_hand) AS total_quantity
FROM tpcds.inventory i
JOIN tpcds.warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_zip = '44593'
  AND i.inv_quantity_on_hand > 600
GROUP BY w.w_warehouse_id, w.w_city
ORDER BY total_quantity DESC
LIMIT 100
