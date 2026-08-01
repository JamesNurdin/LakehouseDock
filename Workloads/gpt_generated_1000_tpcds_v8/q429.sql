SELECT DISTINCT d.d_date, i.inv_item_sk, i.inv_quantity_on_hand
FROM inventory i
JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
WHERE d.d_current_quarter = 'Y'
  AND i.inv_quantity_on_hand > 500
LIMIT 100
