WITH hd_ib AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
aggregated AS (
    SELECT
        ib_lower_bound,
        ib_upper_bound,
        COUNT(*) AS household_count,
        AVG(hd_dep_count) AS avg_dependents,
        AVG(hd_vehicle_count) AS avg_vehicles,
        SUM(CASE WHEN hd_buy_potential = 'HIGH' THEN 1 ELSE 0 END) AS high_buy_potential_cnt,
        SUM(CASE WHEN hd_buy_potential = 'MEDIUM' THEN 1 ELSE 0 END) AS medium_buy_potential_cnt,
        SUM(CASE WHEN hd_buy_potential = 'LOW' THEN 1 ELSE 0 END) AS low_buy_potential_cnt
    FROM hd_ib
    GROUP BY ib_lower_bound, ib_upper_bound
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    household_count,
    avg_dependents,
    avg_vehicles,
    high_buy_potential_cnt,
    medium_buy_potential_cnt,
    low_buy_potential_cnt,
    high_buy_potential_cnt * 1.0 / household_count AS high_buy_potential_ratio,
    RANK() OVER (ORDER BY avg_dependents DESC) AS dep_count_rank
FROM aggregated
ORDER BY ib_lower_bound
