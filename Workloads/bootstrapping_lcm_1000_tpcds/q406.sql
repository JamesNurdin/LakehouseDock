SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_day,
    c.c_birth_month,
    c.c_birth_year,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
    COUNT(ss.ss_ticket_number) AS total_transactions,
    MIN(d_sold.d_date) AS earliest_sale_date,
    MAX(d_sold.d_date) AS latest_sale_date,
    d_first_ship.d_year AS first_ship_year,
    d_first_ship.d_month_seq AS first_ship_month_seq,
    d_first_sales.d_year AS first_sales_year,
    COALESCE(d_last_review.d_year, -1) AS last_review_year,
    s.s_store_name,
    s.s_city,
    d_store_closed.d_year AS store_closed_year,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    MIN(d_wp_creation.d_date) AS earliest_web_page_creation,
    MAX(d_wp_access.d_date) AS latest_web_page_access
FROM
    customer c
JOIN
    store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
JOIN
    store s
        ON ss.ss_store_sk = s.s_store_sk
JOIN
    date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN
    date_dim d_first_ship
        ON c.c_first_shipto_date_sk = d_first_ship.d_date_sk
JOIN
    date_dim d_first_sales
        ON c.c_first_sales_date_sk = d_first_sales.d_date_sk
LEFT JOIN
    date_dim d_last_review
        ON c.c_last_review_date = d_last_review.d_date_sk
JOIN
    date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN
    web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
JOIN
    date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN
    date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_day,
    c.c_birth_month,
    c.c_birth_year,
    d_first_ship.d_year,
    d_first_ship.d_month_seq,
    d_first_sales.d_year,
    d_last_review.d_year,
    s.s_store_name,
    s.s_city,
    d_store_closed.d_year
ORDER BY
    total_net_profit DESC
LIMIT 100
