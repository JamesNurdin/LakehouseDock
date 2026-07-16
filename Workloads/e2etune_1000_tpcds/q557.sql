WITH agg AS (
    SELECT
        cc.cc_state,
        cc.cc_city,
        sm.sm_type,
        COUNT(DISTINCT p.p_promo_id) AS promo_count,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(p.p_cost) AS avg_promo_cost
    FROM call_center cc
    JOIN promotion p
        ON cc.cc_open_date_sk = p.p_start_date_sk
    JOIN ship_mode sm
        ON p.p_promo_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_class = 'large'
      AND p.p_discount_active = 'Y'
      AND cc.cc_rec_end_date >= DATE '2000-01-01'
    GROUP BY cc.cc_state, cc.cc_city, sm.sm_type
    HAVING COUNT(*) > 5
)
SELECT
    cc_state,
    cc_city,
    sm_type,
    promo_count,
    total_promo_cost,
    avg_promo_cost,
    RANK() OVER (PARTITION BY cc_state ORDER BY total_promo_cost DESC) AS state_cost_rank
FROM agg
ORDER BY total_promo_cost DESC
LIMIT 100
