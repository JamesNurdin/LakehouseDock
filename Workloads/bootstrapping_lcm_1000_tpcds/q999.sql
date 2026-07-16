SELECT
    d_cc_closed.d_year AS year,
    cc.cc_state,
    s.s_state,
    ws.web_state,
    CASE 
        WHEN cc.cc_tax_percentage > 5 THEN 'HighTax' 
        ELSE 'LowTax' 
    END AS cc_tax_category,
    COUNT(DISTINCT cc.cc_call_center_id) AS call_center_cnt,
    COUNT(DISTINCT s.s_store_id) AS store_cnt,
    COUNT(DISTINCT ws.web_site_id) AS web_site_cnt,
    COUNT(DISTINCT wp.wp_web_page_id) AS page_cnt,
    SUM(cc.cc_employees) AS total_cc_employees,
    SUM(s.s_number_employees) AS total_store_employees,
    SUM(s.s_floor_space) AS total_store_floor_space,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct,
    AVG(ws.web_tax_percentage) AS avg_web_tax_pct,
    SUM(wp.wp_char_count) AS total_page_chars,
    SUM(wp.wp_image_count) AS total_page_images,
    AVG(date_diff('day', d_ws_open.d_date, d_ws_close.d_date)) AS avg_site_open_duration_days,
    AVG(date_diff('day', d_wp_creation.d_date, d_wp_access.d_date)) AS avg_page_lifetime_days
FROM call_center cc
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open   ON cc.cc_open_date_sk   = d_cc_open.d_date_sk
CROSS JOIN date_dim d_store
JOIN store s ON s.s_closed_date_sk = d_store.d_date_sk
CROSS JOIN date_dim d_ws_open
JOIN web_site ws ON ws.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
CROSS JOIN date_dim d_wp_creation
JOIN web_page wp ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_cc_closed.d_year = d_store.d_year
  AND d_cc_closed.d_year = d_ws_open.d_year
  AND d_cc_closed.d_year = d_ws_close.d_year
  AND d_cc_closed.d_year = d_wp_creation.d_year
  AND d_cc_closed.d_year = d_wp_access.d_year
GROUP BY
    d_cc_closed.d_year,
    cc.cc_state,
    s.s_state,
    ws.web_state,
    CASE 
        WHEN cc.cc_tax_percentage > 5 THEN 'HighTax' 
        ELSE 'LowTax' 
    END
LIMIT 100
