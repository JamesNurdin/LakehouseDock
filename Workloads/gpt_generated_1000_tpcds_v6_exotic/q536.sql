WITH hd_income AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM tpcds.household_demographics hd
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        hd.hd_buy_potential IN ('>10000', '5001-10000', '1001-5000')
        AND hd.hd_vehicle_count >= 0
        AND hd.hd_dep_count BETWEEN 0 AND 5
        AND ib.ib_lower_bound > 30000
        AND ib.ib_upper_bound <= 150000
        AND hd.hd_income_band_sk IN (1, 2, 10, 18)
)
SELECT
    hd_demo_sk,
    hd_income_band_sk,
    hd_buy_potential,
    hd_dep_count,
    hd_vehicle_count,
    ib_lower_bound,
    ib_upper_bound,
    CASE
        WHEN hd_vehicle_count = 0 THEN 'NoVehicle'
        WHEN hd_vehicle_count = 1 THEN 'OneVehicle'
        ELSE 'MultipleVehicles'
    END AS vehicle_category,
    ROW_NUMBER() OVER (PARTITION BY hd_income_band_sk ORDER BY hd_vehicle_count DESC) AS vehicle_rank,
    AVG(hd_vehicle_count) OVER (PARTITION BY hd_income_band_sk) AS avg_vehicle_per_band,
    (
        SELECT COUNT(*)
        FROM tpcds.household_demographics hd2
        WHERE hd2.hd_income_band_sk = hd_income_band_sk
    ) AS total_households_in_band
FROM hd_income
WHERE hd_vehicle_count > (
    SELECT AVG(hd_vehicle_count)
    FROM tpcds.household_demographics
)
ORDER BY hd_income_band_sk, vehicle_rank
LIMIT 100
