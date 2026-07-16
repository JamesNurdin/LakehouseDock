SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_year,
    c.c_preferred_cust_flag,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    d_ship.d_date AS ship_date,
    d_ship.d_year AS ship_year,
    d_sales.d_date AS sales_date,
    d_sales.d_year AS sales_year,
    d_create.d_date AS page_creation_date,
    d_create.d_year AS page_creation_year,
    d_access.d_date AS page_access_date,
    d_access.d_year AS page_access_year,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s.s_floor_space,
    wp.wp_url,
    wp.wp_type,
    wp.wp_char_count
FROM customer c
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_create ON wp.wp_creation_date_sk = d_create.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_create.d_date_sk
ORDER BY c.c_customer_id
LIMIT 100
