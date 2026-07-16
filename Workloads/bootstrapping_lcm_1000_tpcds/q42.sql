SELECT
    cc.cc_call_center_id,
    cc.cc_name AS call_center_name,
    cc.cc_state,
    d_cc_open.d_year AS cc_open_year,
    d_cc_closed.d_year AS cc_closed_year,
    s.s_store_id,
    s.s_store_name,
    s.s_state AS store_state,
    d_store_closed.d_year AS store_closed_year,
    ws.web_site_id,
    ws.web_name,
    ws.web_state AS website_state,
    d_ws_open.d_year AS web_site_open_year,
    d_cc_closed.d_year AS web_site_close_year,
    wp.wp_web_page_id,
    wp.wp_url,
    d_wp_access.d_year AS wp_access_year,
    cc.cc_employees,
    s.s_number_employees,
    ws.web_tax_percentage,
    wp.wp_image_count,
    wp.wp_link_count,
    (cc.cc_tax_percentage + s.s_tax_percentage + ws.web_tax_percentage) / 3.0 AS avg_tax_percentage,
    (cc.cc_sq_ft + s.s_floor_space) AS total_sq_ft,
    (cc.cc_employees + s.s_number_employees) AS total_employees,
    (wp.wp_image_count * wp.wp_link_count) AS page_interaction_score,
    CASE
        WHEN d_cc_closed.d_year < 2000 THEN 'Pre-2000'
        WHEN d_cc_closed.d_year BETWEEN 2000 AND 2010 THEN '2000-2010'
        ELSE 'Post-2010'
    END AS closed_period_category
FROM call_center cc
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_site ws
    ON ws.web_close_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_ws_open
    ON ws.web_open_date_sk = d_ws_open.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE cc.cc_employees > 100
  AND s.s_number_employees > 50
  AND wp.wp_image_count IS NOT NULL
ORDER BY cc.cc_call_center_id, d_cc_closed.d_year DESC
LIMIT 100
