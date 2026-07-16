SELECT
    s.s_state,
    s.s_city,
    d_start.d_year AS start_year,
    d_start.d_month_seq AS start_month_seq,
    COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(date_diff('day', d_start.d_date, d_end.d_date)) AS avg_promo_duration_days,
    MAX(p.p_response_target) AS max_response_target,
    CASE
        WHEN SUM(p.p_cost) > 100000 THEN 'HIGH'
        WHEN SUM(p.p_cost) > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS cost_category,
    SUM(CASE WHEN d_start.d_weekend = 'Y' THEN 1 ELSE 0 END) AS start_on_weekend_cnt
FROM promotion p
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE p.p_cost > 0
    AND s.s_gmt_offset BETWEEN -5 AND -3
    AND d_start.d_year >= 2015
GROUP BY
    s.s_state,
    s.s_city,
    d_start.d_year,
    d_start.d_month_seq
HAVING COUNT(DISTINCT p.p_promo_id) >= 5
ORDER BY total_promo_cost DESC
LIMIT 100
