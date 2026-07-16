SELECT
    cp.cp_department,
    cp.cp_catalog_page_number,
    d_cp_start.d_date AS catalog_start_date,
    d_cp_end.d_date AS catalog_end_date,
    p.p_promo_name,
    p.p_cost,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_market_desc,
    date_diff('day', d_cp_start.d_date, d_cp_end.d_date) AS catalog_page_duration_days,
    date_diff('day', d_promo_start.d_date, d_promo_end.d_date) AS promotion_duration_days,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY p.p_cost DESC) AS dept_promo_cost_rank,
    RANK() OVER (PARTITION BY s.s_state ORDER BY p.p_cost DESC) AS state_promo_cost_rank
FROM catalog_page cp
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk >= cp.cp_start_date_sk
   AND p.p_start_date_sk <= cp.cp_end_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_promo_end.d_date_sk
WHERE cp.cp_type = 'Seasonal'
ORDER BY cp.cp_department, dept_promo_cost_rank
LIMIT 200
