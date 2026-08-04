SELECT
  d.d_date,
  i.inv_item_sk,
  SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand
FROM inventory i
JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND i.inv_warehouse_sk IN (2, 9)
GROUP BY d.d_date, i.inv_item_sk
ORDER BY d.d_date ASC, total_quantity_on_hand DESC
