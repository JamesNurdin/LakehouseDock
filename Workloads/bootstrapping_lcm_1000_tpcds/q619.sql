SELECT
    CONCAT(CAST(d_store.d_year AS VARCHAR), '-Q', CAST(d_store.d_quarter_seq AS VARCHAR)) AS closed_quarter,
    (d_store.d_year * 10 + d_store.d_quarter_seq) AS period_key,
    s.s_store_name,
    s.s_state,
    COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
    SUM(p.p_cost) AS total_promo_cost,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    AVG(p.p_response_target) AS avg_response_target,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN i.inv_quantity_on_hand ELSE 0 END) AS discounted_inventory_qty,
    COUNT(DISTINCT CASE WHEN p.p_channel_tv IS NOT NULL THEN p.p_promo_id END) AS tv_promo_cnt,
    MIN(d_start.d_date) AS earliest_promo_start,
    MAX(d_end.d_date) AS latest_promo_end,
    SUM(i.inv_quantity_on_hand) FILTER (WHERE d_inv.d_month_seq = d_store.d_month_seq) AS inventory_same_month_as_closure
FROM store s
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
JOIN inventory i ON i.inv_date_sk = d_store.d_date_sk
JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_store.d_date_sk
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
GROUP BY
    CONCAT(CAST(d_store.d_year AS VARCHAR), '-Q', CAST(d_store.d_quarter_seq AS VARCHAR)),
    (d_store.d_year * 10 + d_store.d_quarter_seq),
    s.s_store_name,
    s.s_state
HAVING SUM(i.inv_quantity_on_hand) > 0
