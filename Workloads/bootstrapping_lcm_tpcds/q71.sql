SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_shipto.d_date AS first_ship_date,
    d_sales.d_date AS first_sales_date,
    d_review.d_date AS last_review_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    SUM(i.inv_quantity_on_hand) AS total_inventory_quantity,
    COUNT(DISTINCT wp.wp_web_page_id) AS total_web_pages,
    SUM(wp.wp_char_count) AS total_web_page_characters,
    COUNT(CASE WHEN d_wp_creation.d_date = d_shipto.d_date THEN 1 END) AS pages_created_on_ship_date,
    COUNT(CASE WHEN d_wp_access.d_date = d_sales.d_date THEN 1 END) AS pages_accessed_on_sales_date
FROM customer c
JOIN date_dim d_shipto
    ON c.c_first_shipto_date_sk = d_shipto.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_review
    ON c.c_last_review_date = d_review.d_date_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_shipto.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_shipto.d_date_sk
WHERE d_shipto.d_year = 2020
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_shipto.d_date,
    d_sales.d_date,
    d_review.d_date,
    s.s_store_name,
    s.s_city,
    s.s_state
HAVING SUM(i.inv_quantity_on_hand) > 1000
ORDER BY total_inventory_quantity DESC
LIMIT 100
