SELECT d.d_date,
       i.inv_item_sk,
       SUM(i.inv_quantity_on_hand) AS total_qty
FROM tpcds.inventory i
JOIN tpcds.date_dim d
  ON i.inv_date_sk = d.d_date_sk
WHERE d.d_moy = 5
  AND d.d_following_holiday = 'N'
  AND i.inv_warehouse_sk = 1
GROUP BY d.d_date, i.inv_item_sk
ORDER BY total_qty DESC
LIMIT 100
