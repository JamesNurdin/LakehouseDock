SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_floor_space,
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    cc.cc_employees,
    cc.cc_sq_ft,
    cp.cp_catalog_page_id,
    cp.cp_type,
    cp.cp_description,
    cp.cp_catalog_page_number,
    wp.wp_url,
    wp.wp_image_count,
    wp.wp_link_count,
    wp.wp_char_count,
    d_store.d_date          AS store_closed_date,
    d_cc_open.d_date        AS cc_open_date,
    d_cp_end.d_date         AS cp_end_date,
    d_wp_access.d_date      AS wp_access_date,
    (s.s_floor_space + cc.cc_sq_ft) AS total_space_sqft,
    (wp.wp_image_count + wp.wp_link_count) AS total_media_units,
    ROW_NUMBER() OVER (
        PARTITION BY s.s_state
        ORDER BY (s.s_floor_space + cc.cc_sq_ft) DESC
    ) AS state_store_rank
FROM store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_store.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_store.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_store.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_cc_open.d_date < d_store.d_date
  AND d_cp_end.d_date >= d_store.d_date
ORDER BY total_space_sqft DESC
LIMIT 100
