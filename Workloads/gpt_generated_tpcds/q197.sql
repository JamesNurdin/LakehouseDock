WITH hd_ib AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM household_demographics AS hd
    JOIN income_band AS ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential IN ('High', 'Medium')
),
agg AS (
    SELECT
        ib_lower_bound,
        ib_upper_bound,
        COUNT(*) AS household_count,
        AVG(hd_dep_count) AS avg_dependents,
        AVG(hd_vehicle_count) AS avg_vehicles
    FROM hd_ib
    GROUP BY ib_lower_bound, ib_upper_bound
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    household_count,
    avg_dependents,
    avg_vehicles,
    ROW_NUMBER() OVER (ORDER BY avg_vehicles DESC) AS vehicle_count_rank
FROM agg
ORDER BY avg_vehicles DESC
