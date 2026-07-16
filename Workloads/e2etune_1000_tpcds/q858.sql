SELECT ib.ib_income_band_sk,
       r.r_reason_desc,
       COUNT(*) AS item_count,
       SUM(inv.inv_quantity_on_hand) AS total_quantity,
       AVG(inv.inv_quantity_on_hand) AS avg_quantity,
       MIN(inv.inv_quantity_on_hand) AS min_quantity,
       MAX(inv.inv_quantity_on_hand) AS max_quantity
FROM inventory inv
JOIN income_band ib
  ON inv.inv_quantity_on_hand BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
LEFT JOIN reason r
  ON inv.inv_item_sk = r.r_reason_sk
WHERE inv.inv_date_sk BETWEEN 2450800 AND 2451100
  AND ib.ib_income_band_sk IN (1, 2, 3, 4, 5)
GROUP BY ib.ib_income_band_sk, r.r_reason_desc
HAVING COUNT(*) > 0
ORDER BY total_quantity DESC
LIMIT 20
