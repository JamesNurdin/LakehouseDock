SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city AS customer_city,
    ca.ca_state AS customer_state,
    s.s_store_name,
    s.s_city AS store_city,
    d_ship.d_date AS first_ship_date,
    d_ship.d_year AS ship_year,
    d_sales.d_year AS sales_year,
    d_closure.d_date AS store_closed_date,
    wp.wp_url,
    wp.wp_type,
    d_creation.d_date AS page_creation_date,
    d_access.d_date AS page_access_date,
    COUNT(*) OVER (PARTITION BY c.c_customer_id) AS pages_per_customer,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d_access.d_date DESC) AS recent_page_rank
FROM customer c
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
CROSS JOIN store s
JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
ORDER BY pages_per_customer DESC, c.c_customer_id
LIMIT 100
