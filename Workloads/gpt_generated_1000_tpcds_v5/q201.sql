SELECT
  inv_warehouse_sk,
  SUM(inv_quantity_on_hand) AS total_quantity_on_hand
FROM
  inventory
WHERE
  inv_date_sk BETWEEN 2450800 AND 2451100
  AND inv_warehouse_sk IN (3, 12)
GROUP BY
  inv_warehouse_sk
ORDER BY
  total_quantity_on_hand DESC
