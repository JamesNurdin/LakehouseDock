SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_store_closed.d_date AS store_closed_date,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    COUNT(wp.wp_web_page_id) AS total_web_pages,
    SUM(wp.wp_char_count) AS total_characters,
    AVG(wp.wp_char_count) AS avg_characters_per_page,
    MIN(d_access.d_date) AS earliest_page_access,
    MAX(d_access.d_date) AS latest_page_access,
    MIN(d_shipto.d_date) AS earliest_customer_shipto,
    MAX(d_sales.d_date) AS latest_customer_first_sales,
    AVG(d_sales.d_year - c.c_birth_year) AS avg_age_at_first_sales,
    ca.ca_country AS customer_country,
    c.c_birth_year,
    c.c_preferred_cust_flag
FROM store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN customer c
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN date_dim d_shipto
    ON c.c_first_shipto_date_sk = d_shipto.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_store_closed.d_date,
    ca.ca_country,
    c.c_birth_year,
    c.c_preferred_cust_flag
ORDER BY
    distinct_customers DESC,
    total_web_pages DESC
LIMIT 100
