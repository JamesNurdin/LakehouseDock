WITH hd_ib AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM household_demographics AS hd
    JOIN income_band AS ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    COUNT(DISTINCT hd_demo_sk) AS distinct_households,
    AVG(hd_dep_count) AS avg_dependents,
    AVG(hd_vehicle_count) AS avg_vehicles,
    SUM(hd_vehicle_count) * 1.0 / NULLIF(SUM(hd_dep_count), 0) AS avg_vehicles_per_dependent,
    SUM(CASE WHEN hd_buy_potential = 'HIGH'   THEN 1 ELSE 0 END) AS high_buy_potential_households,
    SUM(CASE WHEN hd_buy_potential = 'MEDIUM' THEN 1 ELSE 0 END) AS medium_buy_potential_households,
    SUM(CASE WHEN hd_buy_potential = 'LOW'    THEN 1 ELSE 0 END) AS low_buy_potential_households
FROM hd_ib
GROUP BY ib_lower_bound, ib_upper_bound
ORDER BY ib_lower_bound
