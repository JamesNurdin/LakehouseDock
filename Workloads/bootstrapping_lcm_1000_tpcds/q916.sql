SELECT
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    cp.cp_description,
    d_start.d_date AS catalog_start_date,
    d_end.d_date AS catalog_end_date,
    date_diff('day', d_start.d_date, d_end.d_date) AS catalog_duration_days,
    wp.wp_url,
    wp.wp_type,
    d_access.d_date AS web_page_access_date,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_ship.d_date AS first_ship_date,
    d_sales.d_date AS first_sales_date,
    s.s_store_name,
    s.s_city,
    s.s_tax_percentage,
    ROW_NUMBER() OVER (ORDER BY cp.cp_catalog_number DESC) AS rank
FROM catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_end.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN customer c
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
ORDER BY rank
LIMIT 100
