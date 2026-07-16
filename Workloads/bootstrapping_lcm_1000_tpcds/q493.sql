SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    s.s_state,
    d_ship.d_year AS ship_year,
    d_sales.d_month_seq AS sales_month_seq,
    d_review.d_year AS review_year,
    d_store_closed.d_date AS store_closed_date,
    d_wp_creation.d_date AS page_creation_date,
    d_wp_access.d_date AS page_access_date,
    COUNT(DISTINCT wp.wp_web_page_sk) AS page_count,
    SUM(CASE WHEN wp.wp_type = 'home' THEN 1 ELSE 0 END) AS home_page_count,
    AVG(s.s_tax_percentage) AS avg_state_tax_pct,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d_wp_access.d_date DESC) AS rn_latest_page
FROM store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
CROSS JOIN customer c
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_review
    ON c.c_last_review_date = d_review.d_date_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE s.s_state IS NOT NULL
  AND wp.wp_type IS NOT NULL
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    s.s_state,
    d_ship.d_year,
    d_sales.d_month_seq,
    d_review.d_year,
    d_store_closed.d_date,
    d_wp_creation.d_date,
    d_wp_access.d_date
HAVING COUNT(DISTINCT wp.wp_web_page_sk) > 1
ORDER BY d_wp_access.d_date DESC
LIMIT 100
