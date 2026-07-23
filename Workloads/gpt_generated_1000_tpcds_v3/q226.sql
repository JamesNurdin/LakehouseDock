SELECT DISTINCT i.i_item_id, i.i_color, inv.inv_quantity_on_hand
FROM inventory inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
WHERE inv.inv_quantity_on_hand > 500
  AND i.i_color = 'red'
  AND inv.inv_date_sk = 2451067
LIMIT 100
