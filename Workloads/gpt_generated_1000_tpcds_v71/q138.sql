SELECT
  w.w_warehouse_name,
  w.w_city,
  SUM(i.inv_quantity_on_hand) AS total_qty
FROM tpcds.inventory i
JOIN tpcds.warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.inv_quantity_on_hand > 500
  AND w.w_country = 'United States'
GROUP BY w.w_warehouse_name, w.w_city
ORDER BY total_qty DESC
LIMIT 100
