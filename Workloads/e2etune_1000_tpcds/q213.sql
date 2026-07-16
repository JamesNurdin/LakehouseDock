WITH promo_agg AS (
    SELECT
        p.p_channel_email,
        p.p_channel_radio,
        r.r_reason_desc,
        sm.sm_carrier,
        COUNT(DISTINCT p.p_item_sk) AS distinct_items,
        SUM(p.p_cost) AS total_cost,
        AVG(p.p_response_target) AS avg_response_target
    FROM promotion p
    LEFT JOIN reason r ON p.p_promo_sk = r.r_reason_sk
    LEFT JOIN ship_mode sm ON p.p_channel_tv = sm.sm_type
    WHERE p.p_channel_email = 'N'
      AND p.p_item_sk IN (292022, 218410, 268843, 75794, 234655)
    GROUP BY
        p.p_channel_email,
        p.p_channel_radio,
        r.r_reason_desc,
        sm.sm_carrier
    HAVING SUM(p.p_cost) > 1000
)
SELECT
    p.*,
    RANK() OVER (ORDER BY total_cost DESC) AS cost_rank
FROM promo_agg p
ORDER BY total_cost DESC
LIMIT 10
