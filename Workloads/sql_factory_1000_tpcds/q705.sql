SELECT w.w_warehouse_id,
       w.w_warehouse_name,
       COUNT(DISTINCT i.i_item_id) AS distinct_items,
       SUM(inv.inv_quantity_on_hand) AS total_quantity,
       SUM(inv.inv_quantity_on_hand * i.i_current_price) AS total_inventory_value,
       AVG(i.i_current_price) AS avg_price,
       MAX(CASE WHEN inv.inv_quantity_on_hand < 100 THEN 'Low'
                WHEN inv.inv_quantity_on_hand BETWEEN 100 AND 500 THEN 'Medium'
                ELSE 'High' END) AS most_common_category,
       SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS promo_items_count
FROM inventory inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
GROUP BY w.w_warehouse_id, w.w_warehouse_name
HAVING SUM(inv.inv_quantity_on_hand) > 1000
ORDER BY total_inventory_value DESC
