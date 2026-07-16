SELECT
    p.p_promo_name,
    p.p_discount_active,
    d_store.d_current_month AS store_closed_month,
    d_store.d_year AS store_closed_year,
    d_promo_end.d_current_month AS promo_end_month,
    d_promo_end.d_year AS promo_end_year,
    w.w_warehouse_name,
    w.w_city AS warehouse_city,
    w.w_state AS warehouse_state,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_inv.d_current_day AS inventory_day,
    SUM(i.inv_quantity_on_hand) AS total_quantity,
    AVG(i.inv_quantity_on_hand) AS avg_quantity,
    MIN(i.inv_quantity_on_hand) AS min_quantity,
    MAX(i.inv_quantity_on_hand) AS max_quantity,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items
FROM date_dim d_store
JOIN store s ON s.s_closed_date_sk = d_store.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_store.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN inventory i ON i.inv_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE p.p_discount_active = 'Y' AND i.inv_quantity_on_hand > 0
GROUP BY
    p.p_promo_name,
    p.p_discount_active,
    d_store.d_current_month,
    d_store.d_year,
    d_promo_end.d_current_month,
    d_promo_end.d_year,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_inv.d_current_day
ORDER BY total_quantity DESC
LIMIT 100
