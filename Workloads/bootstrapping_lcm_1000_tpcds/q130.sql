SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d1.d_year AS store_closed_year,
    d1.d_month_seq AS store_closed_month_seq,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d3.d_date AS first_sales_date,
    d4.d_date AS last_review_date,
    date_diff('day', d3.d_date, d4.d_date) AS customer_lifecycle_days,
    p.p_promo_id,
    p.p_promo_name,
    p.p_cost,
    d1.d_date AS promo_start_date,
    d2.d_date AS promo_end_date,
    date_diff('day', d1.d_date, d2.d_date) AS promo_duration_days,
    CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS promo_discount_active_flag,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY p.p_cost DESC) AS promo_rank_by_cost
FROM store s
JOIN date_dim d1
    ON s.s_closed_date_sk = d1.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d1.d_date_sk
JOIN date_dim d2
    ON p.p_end_date_sk = d2.d_date_sk
JOIN customer c
    ON c.c_first_shipto_date_sk = d1.d_date_sk
JOIN date_dim d3
    ON c.c_first_sales_date_sk = d3.d_date_sk
JOIN date_dim d4
    ON c.c_last_review_date = d4.d_date_sk
WHERE p.p_cost > 0
ORDER BY s.s_store_id, promo_rank_by_cost
LIMIT 100
