SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_s.d_year AS store_closed_year,
    p.p_promo_id,
    p.p_promo_name,
    d_ps.d_year AS promo_start_year,
    d_ps.d_month_seq AS promo_start_month_seq,
    d_pe.d_year AS promo_end_year,
    CASE
        WHEN date_diff('day', d_ps.d_date, d_pe.d_date) > 30 THEN 'Long'
        ELSE 'Short'
    END AS promo_duration_category,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_response_target) AS avg_response_target,
    ROUND(SUM(p.p_cost) / NULLIF(COUNT(DISTINCT c.c_customer_id), 0), 2) AS cost_per_customer,
    SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customer_count,
    MIN(d_cft.d_date) AS first_shipto_date,
    MAX(d_cr.d_date) AS last_review_date
FROM store s
JOIN date_dim d_s
    ON s.s_closed_date_sk = d_s.d_date_sk
CROSS JOIN promotion p
JOIN date_dim d_ps
    ON p.p_start_date_sk = d_ps.d_date_sk
    AND d_ps.d_year = d_s.d_year
JOIN date_dim d_pe
    ON p.p_end_date_sk = d_pe.d_date_sk
    AND d_pe.d_year >= d_ps.d_year
JOIN customer c
    ON c.c_first_sales_date_sk = d_ps.d_date_sk
JOIN date_dim d_cft
    ON c.c_first_shipto_date_sk = d_cft.d_date_sk
JOIN date_dim d_cr
    ON c.c_last_review_date = d_cr.d_date_sk
WHERE p.p_discount_active = 'Y'
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_s.d_year,
    p.p_promo_id,
    p.p_promo_name,
    d_ps.d_year,
    d_ps.d_month_seq,
    d_pe.d_year,
    CASE
        WHEN date_diff('day', d_ps.d_date, d_pe.d_date) > 30 THEN 'Long'
        ELSE 'Short'
    END
