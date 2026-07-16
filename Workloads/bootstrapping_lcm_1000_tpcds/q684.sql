SELECT
    ROW_NUMBER() OVER (ORDER BY d_cc_closed.d_date DESC, cc.cc_call_center_id) AS rank,
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_manager,
    cc.cc_state,
    d_cc_closed.d_date AS cc_closed_date,
    d_cc_open.d_date   AS cc_open_date,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    cp.cp_catalog_page_number,
    cp.cp_department,
    cp.cp_type,
    d_start.d_date AS catalog_start_date,
    d_end.d_date   AS catalog_end_date,
    wp.wp_web_page_id,
    wp.wp_url,
    wp.wp_type,
    wp.wp_image_count,
    wp.wp_link_count,
    (wp.wp_image_count * wp.wp_link_count) AS page_interaction_score,
    d_access.d_date AS page_access_date
FROM call_center cc
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open   ON cc.cc_open_date_sk   = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk   = d_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE cc.cc_state = 'TX'
  AND s.s_state   = 'TX'
ORDER BY rank
LIMIT 100
