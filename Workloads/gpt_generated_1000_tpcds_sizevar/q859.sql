SELECT
  w.w_warehouse_name,
  w.w_city,
  SUM(i.inv_quantity_on_hand) AS total_quantity,
  COUNT(DISTINCT i.inv_item_sk) AS distinct_items
FROM tpcds.inventory i
JOIN tpcds.warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.inv_warehouse_sk = 9
  AND w.w_county = 'Walker County'
  AND i.inv_quantity_on_hand > 0
GROUP BY w.w_warehouse_name, w.w_city
ORDER BY total_quantity DESC
