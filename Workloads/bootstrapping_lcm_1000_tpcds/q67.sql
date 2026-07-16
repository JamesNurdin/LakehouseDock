SELECT
    s.s_store_id,
    s.s_store_name,
    CASE WHEN s.s_number_employees >= 1000 THEN 'Large' ELSE 'Small' END AS store_size_category,
    ws.web_site_id,
    ws.web_name,
    d_store.d_year AS store_closed_year,
    d_store.d_date AS store_closed_date,
    d_site_close.d_date AS site_close_date,
    DATE_DIFF('day', d_store.d_date, d_site_close.d_date) AS site_lifespan_days,
    d_sales.d_year AS first_sales_year,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    COUNT(*) AS total_page_views,
    SUM(wp.wp_image_count) AS total_images,
    AVG(wp.wp_max_ad_count) AS avg_max_ads,
    SUM(CASE WHEN wp.wp_type = 'Landing' THEN 1 ELSE 0 END) AS landing_page_count,
    MIN(d_creation.d_date) AS earliest_page_creation,
    MAX(d_access.d_date) AS latest_page_access
FROM store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_store.d_date_sk
JOIN date_dim d_site_close
    ON ws.web_close_date_sk = d_site_close.d_date_sk
JOIN customer c
    ON c.c_first_shipto_date_sk = d_store.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    CASE WHEN s.s_number_employees >= 1000 THEN 'Large' ELSE 'Small' END,
    ws.web_site_id,
    ws.web_name,
    d_store.d_year,
    d_store.d_date,
    d_site_close.d_date,
    d_sales.d_year
ORDER BY d_store.d_year DESC, unique_customers DESC
LIMIT 100
