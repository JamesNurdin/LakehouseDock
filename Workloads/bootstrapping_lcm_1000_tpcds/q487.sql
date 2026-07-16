SELECT
    cc.cc_state AS call_center_state,
    s.s_state AS store_state,
    cd_closed.d_year AS year,
    p.p_promo_name AS promo_name,
    COUNT(DISTINCT cc.cc_call_center_sk) AS num_call_centers,
    COUNT(DISTINCT s.s_store_sk) AS num_stores,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_response_target) AS avg_response_target,
    COUNT(CASE WHEN p.p_discount_active = 'Y' THEN 1 END) AS active_discount_count,
    SUM(CASE WHEN p.p_channel_tv IS NOT NULL THEN p.p_cost ELSE 0 END) AS tv_promo_cost,
    AVG(date_diff('day', cd_open.d_date, cd_closed.d_date)) AS avg_days_open,
    AVG(date_diff('day', pd_start.d_date, pd_end.d_date)) AS avg_promo_duration,
    MIN(pd_start.d_date) AS earliest_promo_start,
    MAX(pd_end.d_date) AS latest_promo_end
FROM call_center cc
JOIN date_dim cd_closed
    ON cc.cc_closed_date_sk = cd_closed.d_date_sk
JOIN date_dim cd_open
    ON cc.cc_open_date_sk = cd_open.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = cd_closed.d_date_sk
JOIN date_dim pd_start
    ON p.p_start_date_sk = pd_start.d_date_sk
JOIN date_dim pd_end
    ON p.p_end_date_sk = pd_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = cd_closed.d_date_sk
JOIN date_dim sd_closed
    ON s.s_closed_date_sk = sd_closed.d_date_sk
WHERE cd_closed.d_year BETWEEN 2015 AND 2020
GROUP BY
    cc.cc_state,
    s.s_state,
    cd_closed.d_year,
    p.p_promo_name
ORDER BY total_promo_cost DESC
LIMIT 100
