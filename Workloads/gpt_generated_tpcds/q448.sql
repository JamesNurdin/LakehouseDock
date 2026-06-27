WITH band_stats AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS household_count,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        AVG(hd.hd_dep_count) AS avg_dep_count,
        SUM(CASE WHEN hd.hd_buy_potential = 'HIGH' THEN 1 ELSE 0 END) AS high_buy_potential_count
    FROM household_demographics AS hd
    JOIN income_band AS ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    band_stats.ib_lower_bound,
    band_stats.ib_upper_bound,
    band_stats.household_count,
    band_stats.avg_vehicle_count,
    band_stats.avg_dep_count,
    band_stats.high_buy_potential_count,
    RANK() OVER (ORDER BY band_stats.avg_vehicle_count DESC) AS vehicle_count_rank
FROM band_stats
ORDER BY band_stats.ib_lower_bound
