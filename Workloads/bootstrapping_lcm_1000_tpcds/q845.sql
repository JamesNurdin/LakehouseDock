SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.c_email_address,
    c.c_birth_year,
    d_closed.d_date AS store_closed_date,
    d_closed.d_year AS store_closed_year,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_country,
    p.p_promo_name,
    p.p_discount_active,
    p.p_cost,
    d_promo_start.d_date AS promo_start_date,
    d_closed.d_date AS promo_end_date,
    date_diff('day', d_promo_start.d_date, d_closed.d_date) AS promo_duration_days,
    d_promo_start.d_year AS promo_start_year,
    d_promo_start.d_month_seq AS promo_start_month_seq,
    d_sales.d_date AS first_sales_date,
    d_sales.d_year AS first_sales_year,
    d_review.d_date AS last_review_date,
    (d_sales.d_year - c.c_birth_year) AS age_at_first_sales,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    hd.hd_buy_potential,
    hd.hd_income_band_sk,
    CASE
        WHEN p.p_response_target > 1000 THEN 'High'
        WHEN p.p_response_target > 500 THEN 'Medium'
        ELSE 'Low'
    END AS response_level,
    date_diff('day', d_sales.d_date, d_closed.d_date) AS days_between_sales_and_store_close
FROM
    store s
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN promotion p ON p.p_end_date_sk = d_closed.d_date_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN customer c ON c.c_first_shipto_date_sk = d_promo_start.d_date_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
    JOIN date_dim d_review ON c.c_last_review_date = d_review.d_date_sk
ORDER BY
    promo_duration_days DESC,
    age_at_first_sales ASC,
    c.c_customer_id
LIMIT 100
