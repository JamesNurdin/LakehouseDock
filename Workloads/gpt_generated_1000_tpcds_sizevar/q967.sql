WITH sampled_hd AS (
    SELECT *
    FROM household_demographics
    TABLESAMPLE BERNOULLI (10)
    WHERE hd_dep_count BETWEEN 2 AND 7
      AND hd_vehicle_count > 0
      AND hd_buy_potential IN ('>10000', '5001-10000')
)
SELECT *
FROM (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(sampled_hd.hd_demo_sk) AS household_cnt,
        SUM(sampled_hd.hd_vehicle_count) AS total_vehicles,
        AVG(sampled_hd.hd_dep_count) AS avg_dependents,
        MIN(sampled_hd.hd_vehicle_count) AS min_vehicles,
        MAX(sampled_hd.hd_vehicle_count) AS max_vehicles
    FROM sampled_hd
    JOIN income_band ib
      ON sampled_hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 40001
      AND ib.ib_upper_bound <= (SELECT MAX(ib_upper_bound) FROM income_band)
      AND NOT EXISTS (
            SELECT 1
            FROM household_demographics hd2
            WHERE hd2.hd_income_band_sk = sampled_hd.hd_income_band_sk
              AND hd2.hd_vehicle_count > sampled_hd.hd_vehicle_count
        )
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound

    UNION

    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(sampled_hd.hd_demo_sk) AS household_cnt,
        SUM(sampled_hd.hd_vehicle_count) AS total_vehicles,
        AVG(sampled_hd.hd_dep_count) AS avg_dependents,
        MIN(sampled_hd.hd_vehicle_count) AS min_vehicles,
        MAX(sampled_hd.hd_vehicle_count) AS max_vehicles
    FROM sampled_hd
    JOIN income_band ib
      ON sampled_hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sampled_hd.hd_buy_potential = '>10000'
      AND ib.ib_lower_bound BETWEEN 80001 AND 120000
      AND NOT EXISTS (
            SELECT 1
            FROM income_band ib2
            WHERE ib2.ib_income_band_sk = ib.ib_income_band_sk
              AND ib2.ib_upper_bound < ib.ib_upper_bound
        )
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
) AS combined
ORDER BY household_cnt DESC, total_vehicles DESC
LIMIT 100
