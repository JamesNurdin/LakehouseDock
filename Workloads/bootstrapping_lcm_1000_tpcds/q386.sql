SELECT
    cc.cc_call_center_id,
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    dd.d_date AS event_date,
    dd_open.d_date AS call_center_open_date,
    dd_promo_end.d_date AS latest_promotion_end_date,
    SUM(p.p_cost) AS total_promotion_cost,
    COUNT(DISTINCT p.p_promo_id) AS promotion_count,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_page_created_count,
    MAX(wp.wp_url) AS sample_web_page_url,
    RANK() OVER (PARTITION BY cc.cc_call_center_id ORDER BY SUM(p.p_cost) DESC) AS promo_cost_rank
FROM call_center cc
JOIN date_dim dd
    ON cc.cc_closed_date_sk = dd.d_date_sk
JOIN date_dim dd_open
    ON cc.cc_open_date_sk = dd_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dd.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = dd.d_date_sk
JOIN date_dim dd_promo_end
    ON p.p_end_date_sk = dd_promo_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = dd.d_date_sk
JOIN date_dim dd_wp_access
    ON wp.wp_access_date_sk = dd_wp_access.d_date_sk
WHERE dd.d_date IS NOT NULL
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    dd.d_date,
    dd_open.d_date,
    dd_promo_end.d_date
ORDER BY total_promotion_cost DESC
LIMIT 100
