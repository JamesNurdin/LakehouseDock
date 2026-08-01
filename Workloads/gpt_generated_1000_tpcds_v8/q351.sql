SELECT d.d_date,
       i.inv_warehouse_sk,
       SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand
FROM inventory i
JOIN date_dim d
  ON i.inv_date_sk = d.d_date_sk
WHERE d.d_same_day_lq = 2414949
  AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
GROUP BY d.d_date, i.inv_warehouse_sk
ORDER BY total_quantity_on_hand DESC
LIMIT 100
