SELECT w.w_warehouse_id,
       w.w_warehouse_name,
       i.i_item_id,
       i.i_product_name,
       inv.inv_quantity_on_hand,
       i.i_current_price,
       (inv.inv_quantity_on_hand * i.i_current_price) AS inventory_value,
       NTILE(4) OVER (PARTITION BY w.w_warehouse_id ORDER BY (inv.inv_quantity_on_hand * i.i_current_price) DESC) AS inventory_quartile,
       LAG(i.i_current_price) OVER (PARTITION BY w.w_warehouse_id ORDER BY inv.inv_quantity_on_hand) AS prev_price,
       LEAD(i.i_current_price) OVER (PARTITION BY w.w_warehouse_id ORDER BY inv.inv_quantity_on_hand) AS next_price
FROM inventory inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE inv.inv_quantity_on_hand BETWEEN 50 AND 1000
ORDER BY w.w_warehouse_id, inventory_value DESC
