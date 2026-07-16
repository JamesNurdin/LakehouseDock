SELECT
    cc.cc_name,
    cc.cc_country,
    cc.cc_tax_percentage,
    d_cc_closed.d_date AS cc_closed_date,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_open.d_date AS cc_open_date,
    d_cc_open.d_year AS cc_open_year,
    cp.cp_type,
    cp.cp_description,
    s.s_store_name,
    s.s_city,
    s.s_floor_space,
    s.s_market_id,
    wp.wp_url,
    wp.wp_type,
    d_wp_access.d_day_name AS wp_access_day,
    d_cc_closed.d_holiday AS cc_closed_holiday,
    (s.s_floor_space * cc.cc_tax_percentage) AS adjusted_floor_space
FROM call_center cc
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d_cc_closed.d_date_sk
   AND cp.cp_start_date_sk = d_cc_open.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE cc.cc_country IS NOT NULL
ORDER BY adjusted_floor_space DESC, cc.cc_tax_percentage ASC
LIMIT 100
