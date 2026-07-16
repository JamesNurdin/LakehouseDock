SELECT
    s.s_city,
    s.s_state,
    cp.cp_type,
    cp.cp_department,
    d_ref.d_year AS reference_year,
    d_ref.d_month_seq AS reference_month_seq,
    d_sales.d_year AS sales_year,
    d_ship.d_year AS ship_year,
    d_end.d_year AS catalog_end_year,
    d_access.d_year AS access_year,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(CASE WHEN wp.wp_type = 'article' THEN 1 ELSE 0 END) AS article_page_count,
    AVG(wp.wp_char_count) AS avg_char_count,
    MIN(cp.cp_catalog_number) AS min_catalog_number,
    MAX(cp.cp_catalog_page_number) AS max_page_number
FROM store s
JOIN date_dim d_ref
    ON s.s_closed_date_sk = d_ref.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_ref.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ref.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN customer c
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
GROUP BY
    s.s_city,
    s.s_state,
    cp.cp_type,
    cp.cp_department,
    d_ref.d_year,
    d_ref.d_month_seq,
    d_sales.d_year,
    d_ship.d_year,
    d_end.d_year,
    d_access.d_year
HAVING COUNT(DISTINCT wp.wp_web_page_sk) > 5
ORDER BY s.s_city, cp.cp_type
