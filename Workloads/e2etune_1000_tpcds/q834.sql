SELECT
    sub.hd_buy_potential,
    sub.hd_income_band_sk,
    sub.p_channel_email,
    sub.promo_cnt,
    sub.total_promo_cost,
    sub.avg_promo_cost,
    sub.avg_vehicle_cnt,
    RANK() OVER (ORDER BY sub.total_promo_cost DESC) AS cost_rank
FROM (
    SELECT
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        p.p_channel_email,
        COUNT(*) AS promo_cnt,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(p.p_cost) AS avg_promo_cost,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt
    FROM promotion p
    JOIN household_demographics hd
        ON hd.hd_demo_sk = p.p_response_target
    WHERE hd.hd_vehicle_count > 0
        AND p.p_cost > 0
        AND p.p_channel_email = 'Y'
    GROUP BY hd.hd_buy_potential, hd.hd_income_band_sk, p.p_channel_email
    HAVING SUM(p.p_cost) > 1000
) sub
ORDER BY sub.total_promo_cost DESC
LIMIT 100
