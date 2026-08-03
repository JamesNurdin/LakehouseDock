WITH hd_income AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CONCAT(CAST(ib.ib_lower_bound AS VARCHAR), '-', CAST(ib.ib_upper_bound AS VARCHAR)) AS income_range
    FROM household_demographics AS hd
    JOIN income_band AS ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    hd_demo_sk,
    hd_buy_potential,
    hd_dep_count,
    hd_vehicle_count,
    income_range
FROM hd_income
WHERE hd_buy_potential = 'High'
  AND hd_vehicle_count >= 2
  AND ib_lower_bound >= 50000
UNION
SELECT
    hd_demo_sk,
    hd_buy_potential,
    hd_dep_count,
    hd_vehicle_count,
    income_range
FROM hd_income
WHERE hd_buy_potential = 'Low'
  AND hd_dep_count <= 2
  AND ib_upper_bound <= 90000
ORDER BY hd_demo_sk
LIMIT 100
