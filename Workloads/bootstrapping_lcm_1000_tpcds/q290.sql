SELECT
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    p.p_promo_name AS promotion_name,
    p.p_cost AS promotion_cost,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    date_diff('day', d_cc_open.d_date, d_cc_closed.d_date) AS call_center_operating_days,
    date_diff('day', d_promo_start.d_date, d_promo_end.d_date) AS promotion_duration_days,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(p.p_cost) AS total_promotion_cost
FROM call_center cc
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN customer c
    ON c.c_first_sales_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_cust_first_sales
    ON c.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
WHERE
    d_cc_open.d_date <= d_promo_start.d_date
    AND d_cc_closed.d_date >= d_promo_end.d_date
    AND d_cust_first_sales.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
GROUP BY
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    p.p_cost,
    d_promo_start.d_date,
    d_promo_end.d_date,
    d_cc_open.d_date,
    d_cc_closed.d_date
