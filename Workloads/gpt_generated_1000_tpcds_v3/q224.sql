WITH high_vehicle AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(hd.hd_vehicle_count) AS total_vehicles,
        AVG(hd.hd_dep_count) AS avg_dependents,
        COUNT(DISTINCT hd.hd_demo_sk) AS household_cnt,
        'high_vehicle' AS segment
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count >= 3
      AND ib.ib_upper_bound <= 60000
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
low_vehicle AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(hd.hd_vehicle_count) AS total_vehicles,
        AVG(hd.hd_dep_count) AS avg_dependents,
        COUNT(DISTINCT hd.hd_demo_sk) AS household_cnt,
        'low_vehicle' AS segment
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count <= 1
      AND ib.ib_lower_bound >= 50001
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_vehicles,
    avg_dependents,
    household_cnt,
    segment
FROM high_vehicle
UNION ALL
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_vehicles,
    avg_dependents,
    household_cnt,
    segment
FROM low_vehicle
ORDER BY ib_income_band_sk, segment
LIMIT 100
