SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    d_ship.d_date AS shipto_date,
    d_ship.d_day_name AS shipto_day_name,
    d_sales.d_date AS first_sales_date,
    d_sales.d_day_name AS first_sales_day_name,
    d_rev.d_date AS last_review_date,
    d_rev.d_day_name AS last_review_day_name,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    p.p_cost,
    d_start.d_date AS promo_start_date,
    d_start.d_day_name AS promo_start_day_name,
    d_end.d_date AS promo_end_date,
    d_end.d_day_name AS promo_end_day_name,
    date_diff('day', d_start.d_date, d_end.d_date) AS promo_duration_days,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_market_desc,
    s.s_tax_percentage
FROM customer c
JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_rev ON c.c_last_review_date = d_rev.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_ship.d_date_sk
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
JOIN item i ON p.p_item_sk = i.i_item_sk
JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
ORDER BY c.c_last_name ASC, d_start.d_date DESC
LIMIT 100
