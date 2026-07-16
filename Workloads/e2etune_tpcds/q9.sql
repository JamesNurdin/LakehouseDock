WITH hd_agg AS (
    SELECT
        hd_income_band_sk,
        CASE
            WHEN hd_buy_potential = '1001-5000' THEN 'mid'
            WHEN hd_buy_potential = '>10000' THEN 'high'
            ELSE 'low'
        END AS buy_potential_category,
        COUNT(*) AS household_cnt,
        AVG(hd_vehicle_count) AS avg_vehicle_cnt,
        SUM(hd_dep_count) AS total_dep_cnt
    FROM household_demographics
    WHERE hd_vehicle_count >= 1
      AND hd_buy_potential IN ('1001-5000', '>10000')
    GROUP BY hd_income_band_sk,
        CASE
            WHEN hd_buy_potential = '1001-5000' THEN 'mid'
            WHEN hd_buy_potential = '>10000' THEN 'high'
            ELSE 'low'
        END
),
sm_agg AS (
    SELECT
        sm_contract,
        COUNT(*) AS ship_mode_cnt,
        AVG(sm_ship_mode_sk) AS avg_ship_mode_sk
    FROM ship_mode
    WHERE sm_contract IN ('YvxVaJI10', 'HVDFCcQ')
    GROUP BY sm_contract
),
time_agg AS (
    SELECT
        t_shift,
        COUNT(*) AS time_cnt,
        AVG(t_hour) AS avg_hour
    FROM time_dim
    WHERE t_meal_time = 'Breakfast' OR t_meal_time = 'Lunch'
    GROUP BY t_shift
)
SELECT
    hd.hd_income_band_sk,
    hd.buy_potential_category,
    hd.household_cnt,
    hd.avg_vehicle_cnt,
    hd.total_dep_cnt,
    sm.sm_contract,
    sm.ship_mode_cnt,
    sm.avg_ship_mode_sk,
    ti.t_shift,
    ti.time_cnt,
    ti.avg_hour,
    RANK() OVER (ORDER BY hd.household_cnt DESC) AS hd_income_rank,
    ROW_NUMBER() OVER (PARTITION BY sm.sm_contract ORDER BY sm.ship_mode_cnt DESC) AS sm_contract_rnk
FROM hd_agg hd
JOIN sm_agg sm ON true
JOIN time_agg ti ON true
ORDER BY hd.household_cnt DESC, sm.ship_mode_cnt DESC
LIMIT 100
