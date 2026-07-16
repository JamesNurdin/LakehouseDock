SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_base.d_date AS store_closed_and_review_date,
    w.wp_url,
    w.wp_max_ad_count,
    d_creation.d_date AS wp_creation_date,
    d_access.d_date AS wp_access_date,
    date_diff('day', d_creation.d_date, d_access.d_date) AS days_between_creation_and_access,
    d_sales.d_date AS first_sales_date,
    d_ship.d_date AS first_ship_date,
    date_diff('day', d_sales.d_date, d_ship.d_date) AS days_between_sales_and_ship
FROM date_dim d_base
JOIN store s
    ON s.s_closed_date_sk = d_base.d_date_sk
JOIN customer c
    ON c.c_last_review_date = d_base.d_date_sk
JOIN web_page w
    ON w.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_creation
    ON w.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON w.wp_access_date_sk = d_access.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
WHERE d_creation.d_year = 2020
ORDER BY days_between_creation_and_access DESC, c.c_customer_id
LIMIT 100
