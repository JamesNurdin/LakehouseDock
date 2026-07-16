SELECT
    d_closed.d_year AS year,
    d_closed.d_month_seq AS month,
    COUNT(DISTINCT cc.cc_call_center_sk) AS num_call_centers,
    COUNT(DISTINCT s.s_store_sk) AS num_stores,
    COUNT(DISTINCT ws.web_site_sk) AS num_web_sites,
    COUNT(DISTINCT wp.wp_web_page_sk) AS num_web_pages,
    SUM(cc.cc_employees) AS total_cc_employees,
    SUM(s.s_number_employees) AS total_store_employees,
    SUM(s.s_floor_space) AS total_store_floor_space,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct,
    AVG(ws.web_tax_percentage) AS avg_ws_tax_pct,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    SUM(wp.wp_char_count) AS total_char_count,
    COUNT(*) FILTER (WHERE d_open.d_year = d_closed.d_year AND d_open.d_month_seq = d_closed.d_month_seq) AS same_month_open,
    CASE
        WHEN SUM(s.s_floor_space) > 1000000 THEN 'Huge'
        WHEN SUM(s.s_floor_space) > 500000 THEN 'Large'
        ELSE 'Medium'
    END AS store_floor_category
FROM call_center cc
JOIN date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_closed.d_date_sk
JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_closed.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_closed.d_year >= 2020
  AND d_wp_access.d_date > d_closed.d_date
GROUP BY d_closed.d_year, d_closed.d_month_seq
HAVING COUNT(DISTINCT cc.cc_call_center_sk) > 0
ORDER BY d_closed.d_year DESC, d_closed.d_month_seq DESC
LIMIT 100
