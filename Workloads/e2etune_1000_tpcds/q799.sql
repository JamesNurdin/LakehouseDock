SELECT
    s.s_state,
    sm.sm_type,
    t.t_shift,
    COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
    SUM(p.p_cost) AS total_cost,
    AVG(p.p_response_target) AS avg_response_target,
    MIN(p.p_start_date_sk) AS earliest_start_date_sk,
    MAX(p.p_end_date_sk) AS latest_end_date_sk
FROM store s
JOIN promotion p
    ON s.s_store_id = p.p_promo_id
JOIN ship_mode sm
    ON sm.sm_ship_mode_id = p.p_channel_catalog
JOIN time_dim t
    ON p.p_start_date_sk = t.t_time_sk
WHERE p.p_discount_active = 'Y'
  AND s.s_closed_date_sk IS NULL
  AND t.t_shift = 'Evening'
GROUP BY s.s_state, sm.sm_type, t.t_shift
HAVING COUNT(DISTINCT p.p_promo_id) > 2
ORDER BY total_cost DESC
LIMIT 100
