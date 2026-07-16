SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    d_sales.d_year AS sales_year,
    d_sales.d_date AS sales_date,
    d_shipto.d_year AS shipto_year,
    d_shipto.d_date AS shipto_date,
    ws.web_name,
    ws.web_city,
    d_wp_creation.d_year AS page_creation_year,
    d_wp_creation.d_date AS page_creation_date,
    d_wp_access.d_year AS page_access_year,
    d_wp_access.d_date AS page_access_date,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s.s_country AS store_country,
    d_ws_close.d_year AS site_close_year,
    d_ws_close.d_date AS site_close_date,
    COUNT(DISTINCT wp.wp_web_page_sk) AS num_pages,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    AVG(wp.wp_char_count) AS avg_char_count
FROM customer c
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_shipto
    ON c.c_first_shipto_date_sk = d_shipto.d_date_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ws_close.d_date_sk
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    d_sales.d_year,
    d_sales.d_date,
    d_shipto.d_year,
    d_shipto.d_date,
    ws.web_name,
    ws.web_city,
    d_wp_creation.d_year,
    d_wp_creation.d_date,
    d_wp_access.d_year,
    d_wp_access.d_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_country,
    d_ws_close.d_year,
    d_ws_close.d_date
ORDER BY total_image_count DESC
LIMIT 100
