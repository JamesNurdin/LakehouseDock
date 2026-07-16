SELECT
    cc.cc_division,
    cc.cc_market_manager,
    s.s_state,
    s.s_city,
    d_main.d_year AS year,
    d_main.d_month_seq AS month_seq,
    COUNT(DISTINCT cc.cc_call_center_sk) AS call_center_cnt,
    COUNT(DISTINCT s.s_store_sk) AS store_cnt,
    COUNT(DISTINCT wp.wp_web_page_sk) AS web_page_cnt,
    COUNT(DISTINCT p.p_promo_sk) AS promo_cnt,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_cost) AS avg_promo_cost,
    AVG(wp.wp_image_count) AS avg_image_count,
    SUM(wp.wp_max_ad_count) AS total_max_ad_count,
    AVG(DATE_DIFF('day', d_open.d_date, d_main.d_date)) AS avg_cc_open_to_close_days,
    AVG(DATE_DIFF('day', d_main.d_date, d_access.d_date)) AS avg_wp_creation_to_access_days,
    AVG(DATE_DIFF('day', d_main.d_date, d_promo_end.d_date)) AS avg_promo_duration_days
FROM date_dim d_main
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_main.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_main.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_main.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_main.d_date_sk
LEFT JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
LEFT JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
LEFT JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
GROUP BY
    cc.cc_division,
    cc.cc_market_manager,
    s.s_state,
    s.s_city,
    d_main.d_year,
    d_main.d_month_seq
ORDER BY total_promo_cost DESC
LIMIT 100
