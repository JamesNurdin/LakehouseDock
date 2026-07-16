SELECT 
    cp.cp_catalog_page_number,
    cp.cp_type,
    cp.cp_description,
    d_start.d_date AS cp_start_date,
    d_start.d_year AS cp_start_year,
    d_start.d_month_seq AS cp_start_month_seq,
    d_end.d_date AS cp_end_date,
    d_end.d_year AS cp_end_year,
    d_end.d_month_seq AS cp_end_month_seq,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s.s_number_employees,
    ws.web_name,
    ws.web_state AS web_state,
    ws.web_city AS web_city,
    d_web_close.d_date AS web_close_date,
    wp.wp_url,
    wp.wp_type,
    wp.wp_char_count,
    wp.wp_image_count,
    d_wp_access.d_date AS wp_access_date
FROM catalog_page cp
JOIN date_dim d_start 
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end 
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s 
    ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_site ws 
    ON ws.web_open_date_sk = d_end.d_date_sk
JOIN date_dim d_web_close 
    ON ws.web_close_date_sk = d_web_close.d_date_sk
JOIN web_page wp 
    ON wp.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim d_wp_access 
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
ORDER BY d_start.d_date, cp.cp_catalog_page_number
LIMIT 100
