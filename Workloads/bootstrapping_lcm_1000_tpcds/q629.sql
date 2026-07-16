SELECT
    d_base.d_year,
    d_base.d_quarter_seq,
    s.s_state,
    COUNT(DISTINCT s.s_store_id) AS store_count,
    COUNT(DISTINCT ws.web_site_id) AS website_count,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_cost) AS avg_promo_cost,
    MAX(p.p_response_target) AS max_response_target,
    MIN(d_promo_end.d_date) AS earliest_promo_end_date,
    MAX(d_web_close.d_date) AS latest_web_close_date
FROM date_dim d_base
JOIN store s
    ON s.s_closed_date_sk = d_base.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_base.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_base.d_date_sk
JOIN date_dim d_web_close
    ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE p.p_discount_active = 'Y'
GROUP BY d_base.d_year, d_base.d_quarter_seq, s.s_state
ORDER BY total_promo_cost DESC
LIMIT 50
