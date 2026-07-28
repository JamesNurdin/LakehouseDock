SELECT
  w.w_warehouse_name,
  w.w_city,
  SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand
FROM tpcds.inventory i
JOIN tpcds.warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.inv_date_sk = 2451081
  AND w.w_suite_number = 'Suite 480'
GROUP BY
  w.w_warehouse_name,
  w.w_city
LIMIT 100
