SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_type,
    d_cp_start.d_date AS catalog_start_date,
    d_store_closed.d_date AS catalog_end_and_store_closed_date,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    d_cust_first_sales.d_date AS first_sales_date,
    (year(d_cust_first_sales.d_date) - c.c_birth_year) AS age_at_first_purchase,
    p.p_promo_name,
    p.p_cost,
    p.p_discount_active,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    date_diff('day', d_cp_start.d_date, d_store_closed.d_date) AS catalog_page_duration_days,
    date_diff('day', d_promo_start.d_date, d_promo_end.d_date) AS promo_duration_days,
    date_diff('day', d_store_closed.d_date, d_promo_start.d_date) AS days_between_store_closure_and_promo_start,
    CASE
        WHEN date_diff('day', d_promo_start.d_date, d_promo_end.d_date) > 0
        THEN p.p_cost / date_diff('day', d_promo_start.d_date, d_promo_end.d_date)
        ELSE NULL
    END AS promo_cost_per_day
FROM
    store s
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN customer c ON c.c_first_shipto_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cust_first_sales ON c.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE
    p.p_discount_active = 'Y'
    AND s.s_state = 'CA'
    AND cp.cp_type = 'Seasonal'
    AND d_cp_start.d_year = 2022
ORDER BY
    promo_cost_per_day DESC NULLS LAST
LIMIT 100
