SELECT
    d_start.d_year,
    d_start.d_month_seq,
    s.s_store_id,
    s.s_city,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    p.p_cost,
    i.inv_item_sk,
    i.inv_quantity_on_hand,
    d_start.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date,
    date_diff('day', d_start.d_date, d_end.d_date) AS promo_duration_days,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY i.inv_quantity_on_hand DESC) AS quantity_rank
FROM date_dim d_start
JOIN promotion p
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_start.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_start.d_date_sk
WHERE d_start.d_year = 2022
  AND p.p_discount_active = 'Y'
ORDER BY promo_duration_days DESC, quantity_rank
LIMIT 200
