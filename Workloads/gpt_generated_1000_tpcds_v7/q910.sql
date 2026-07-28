WITH promo_join AS (
    SELECT
        p.p_promo_id,
        p.p_cost,
        p.p_channel_tv,
        p.p_start_date_sk,
        p.p_end_date_sk,
        s.s_state,
        s.s_tax_percentage,
        d_start.d_year,
        d_start.d_current_month,
        d_start.d_last_dom
    FROM promotion p
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_end.d_date_sk
    WHERE p.p_channel_tv = 'N'
      AND p.p_promo_id = 'AAAAAAAADBAAAAAA'
      AND p.p_cost > 5000
      AND s.s_state = 'CA'
      AND s.s_tax_percentage >= 0.07
      AND d_start.d_current_month = 'Y'
      AND d_start.d_last_dom > 2415400
)
SELECT
    s_state,
    p_channel_tv,
    d_year,
    COUNT(p_promo_id) AS promo_cnt,
    SUM(p_cost) AS total_cost,
    AVG(p_cost) AS avg_cost,
    MIN(p_cost) AS min_cost,
    MAX(p_cost) AS max_cost,
    RANK() OVER (PARTITION BY s_state ORDER BY SUM(p_cost) DESC) AS cost_rank,
    SUM(SUM(p_cost)) OVER (PARTITION BY s_state) AS state_total_cost
FROM promo_join
GROUP BY s_state, p_channel_tv, d_year
ORDER BY total_cost DESC
LIMIT 100
