SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    cp.cp_catalog_page_number,
    d_start.d_year AS start_year,
    d_end.d_year AS end_year,
    d_end.d_quarter_name AS end_quarter,
    ws.web_site_id,
    ws.web_name,
    d_end.d_year AS ws_open_year,
    d_ws_close.d_year AS ws_close_year,
    s.s_store_id,
    s.s_state,
    s.s_number_employees,
    wp.wp_web_page_id,
    wp.wp_url,
    wp.wp_max_ad_count,
    wp.wp_image_count,
    wp_access.d_year AS wp_access_year,
    COUNT(*) OVER (PARTITION BY d_end.d_year) AS pages_per_year,
    AVG(s.s_number_employees) OVER (PARTITION BY d_end.d_year) AS avg_employees_per_year,
    SUM(wp.wp_max_ad_count) OVER (PARTITION BY d_end.d_year) AS total_ads_per_year
FROM catalog_page cp
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_end.d_date_sk
JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ws_close.d_date_sk
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim wp_access ON wp.wp_access_date_sk = wp_access.d_date_sk
WHERE d_end.d_year >= 2020
  AND s.s_state = 'CA'
  AND ws.web_state = 'CA'
ORDER BY d_end.d_year DESC, cp.cp_catalog_page_number
LIMIT 200
