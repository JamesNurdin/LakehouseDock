WITH demog_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS household_cnt,
        SUM(hd.hd_vehicle_count) AS total_vehicles,
        AVG(hd.hd_vehicle_count) AS avg_vehicles,
        SUM(hd.hd_dep_count) AS total_dependents,
        AVG(hd.hd_dep_count) AS avg_dependents,
        COUNT(CASE WHEN hd.hd_buy_potential = '>10000' THEN 1 END) AS high_buy_potential_cnt
    FROM household_demographics hd
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count >= 0
      AND hd.hd_dep_count > 0
      AND hd.hd_buy_potential IN ('5001-10000', '>10000', '1001-5000')
      AND ib.ib_lower_bound >= 30000
      AND ib.ib_upper_bound <= 200000
      AND ib.ib_income_band_sk IS NOT NULL
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
overall_stats AS (
    SELECT AVG(avg_vehicles) AS overall_avg_vehicles
    FROM demog_agg
)
SELECT
    d.ib_income_band_sk,
    d.ib_lower_bound,
    d.ib_upper_bound,
    d.household_cnt,
    d.total_vehicles,
    d.avg_vehicles,
    d.total_dependents,
    d.avg_dependents,
    d.high_buy_potential_cnt,
    ROW_NUMBER() OVER (ORDER BY d.avg_vehicles DESC) AS vehicle_avg_rank,
    o.overall_avg_vehicles
FROM demog_agg d
CROSS JOIN overall_stats o
WHERE d.total_vehicles > 10
  AND d.avg_vehicles > o.overall_avg_vehicles
  AND d.household_cnt >= 5
  AND d.high_buy_potential_cnt >= 1
  AND d.ib_lower_bound BETWEEN 30000 AND 150000
ORDER BY d.avg_vehicles DESC, d.ib_income_band_sk
LIMIT 100
