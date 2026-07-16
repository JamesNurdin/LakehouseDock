WITH promo_income AS (
    SELECT
        p.p_promo_id,
        p.p_cost,
        p.p_purpose,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM promotion p
    JOIN income_band ib
        ON p.p_cost BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE p.p_channel_press = 'N'
      AND p.p_purpose = 'Unknown'
),
agg AS (
    SELECT
        pi.ib_income_band_sk,
        pi.ib_lower_bound,
        pi.ib_upper_bound,
        pi.p_purpose,
        COUNT(DISTINCT pi.p_promo_id) AS promo_cnt,
        SUM(pi.p_cost) AS total_cost,
        AVG(pi.p_cost) AS avg_cost,
        COUNT(r.r_reason_id) AS reason_cnt
    FROM promo_income pi
    LEFT JOIN reason r
        ON pi.p_promo_id = r.r_reason_id
    GROUP BY pi.ib_income_band_sk, pi.ib_lower_bound, pi.ib_upper_bound, pi.p_purpose
    HAVING COUNT(DISTINCT pi.p_promo_id) > 5
)
SELECT
    agg.ib_income_band_sk,
    agg.ib_lower_bound,
    agg.ib_upper_bound,
    agg.p_purpose,
    agg.promo_cnt,
    agg.total_cost,
    agg.avg_cost,
    agg.reason_cnt,
    RANK() OVER (ORDER BY agg.total_cost DESC) AS cost_rank
FROM agg
ORDER BY agg.total_cost DESC
LIMIT 100
