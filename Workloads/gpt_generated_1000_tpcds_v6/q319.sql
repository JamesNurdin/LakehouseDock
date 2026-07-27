SELECT
  w.w_city,
  SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand
FROM
  inventory i
JOIN
  warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE
  i.inv_quantity_on_hand > 700
  AND w.w_city = 'Pleasant Grove'
GROUP BY
  w.w_city
LIMIT 100
