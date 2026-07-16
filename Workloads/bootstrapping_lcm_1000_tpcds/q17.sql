SELECT
    cc.cc_name AS call_center_name,
    s.s_store_name AS store_name,
    d_cc_closed.d_date AS call_center_closure_date,
    d_cc_open.d_date AS call_center_open_date,
    i.i_category AS item_category,
    COUNT(DISTINCT i.i_item_id) AS promoted_item_count,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_cost) AS avg_promo_cost,
    AVG(i.i_current_price) AS avg_item_price,
    (AVG(p.p_cost) / NULLIF(AVG(i.i_current_price), 0)) * 100 AS avg_promo_cost_percent_of_price,
    SUM(p.p_cost) / NULLIF(cc.cc_employees, 0) AS promo_cost_per_employee,
    SUM(p.p_cost) / NULLIF(s.s_floor_space, 0) AS promo_cost_per_sqft,
    DATE_DIFF('day', d_cc_open.d_date, d_cc_closed.d_date) AS call_center_lifespan_days,
    DATE_DIFF('day', d_cc_open.d_date, d_promo_end.d_date) AS promo_duration_days,
    (s.s_tax_percentage - cc.cc_tax_percentage) AS tax_percentage_diff
FROM call_center cc
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN item i ON p.p_item_sk = i.i_item_sk
WHERE i.i_category = 'Electronics'
  AND s.s_state = cc.cc_state
  AND d_cc_closed.d_year = 2020
  AND d_promo_end.d_year = 2020
GROUP BY
    cc.cc_name,
    s.s_store_name,
    d_cc_closed.d_date,
    d_cc_open.d_date,
    i.i_category,
    s.s_tax_percentage,
    cc.cc_tax_percentage,
    cc.cc_employees,
    s.s_floor_space,
    d_promo_end.d_date
HAVING SUM(p.p_cost) > 1000
ORDER BY total_promo_cost DESC
LIMIT 100
