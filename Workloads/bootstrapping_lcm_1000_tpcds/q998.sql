SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    COUNT(DISTINCT p.p_promo_id) AS promo_count,
    SUM(i.inv_quantity_on_hand) AS total_quantity,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_cost) AS avg_promo_cost,
    DATE_DIFF('day', MIN(d.d_date), MAX(d_end.d_date)) + 1 AS promo_duration_days,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN i.inv_quantity_on_hand ELSE 0 END) AS discounted_quantity,
    COUNT(*) AS transaction_count
FROM inventory i
JOIN date_dim d
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE d.d_year >= 2020
  AND s.s_state IN ('CA', 'NY', 'TX')
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_state,
    p.p_promo_name
HAVING SUM(i.inv_quantity_on_hand) > 0
ORDER BY
    d.d_year DESC,
    d.d_month_seq,
    total_quantity DESC
