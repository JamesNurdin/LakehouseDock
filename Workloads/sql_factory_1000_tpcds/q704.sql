SELECT w.w_warehouse_id,
       w.w_warehouse_name,
       i.i_item_id,
       i.i_product_name,
       inv.inv_quantity_on_hand,
       i.i_current_price,
       (inv.inv_quantity_on_hand * i.i_current_price) AS inventory_value,
       CASE WHEN p.p_discount_active = 'Y' THEN 'Promoted' ELSE 'Regular' END AS promotion_status,
       SUM((inv.inv_quantity_on_hand * i.i_current_price)) OVER (PARTITION BY w.w_warehouse_id) AS warehouse_total_value,
       RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY i.i_current_price DESC) AS price_rank_in_warehouse
FROM inventory inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
WHERE i.i_category = 'Electronics'
  AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
GROUP BY w.w_warehouse_id, w.w_warehouse_name, i.i_item_id, i.i_product_name, inv.inv_quantity_on_hand, i.i_current_price, p.p_discount_active
ORDER BY warehouse_total_value DESC
