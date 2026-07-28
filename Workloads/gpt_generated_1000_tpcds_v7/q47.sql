WITH hd AS (
    SELECT hd_demo_sk,
           hd_income_band_sk,
           hd_buy_potential,
           hd_dep_count,
           hd_vehicle_count
    FROM tpcds.household_demographics
    WHERE hd_dep_count > 0
      AND hd_vehicle_count >= 0
      AND hd_buy_potential = '5001-10000'
),
ib AS (
    SELECT ib_income_band_sk,
           ib_lower_bound,
           ib_upper_bound
    FROM tpcds.income_band
    WHERE ib_lower_bound >= 50000
      AND ib_upper_bound <= 200000
)
SELECT
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(*) AS household_cnt,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
    MAX(hd.hd_dep_count) AS max_dep_cnt,
    MIN(ib.ib_lower_bound) AS min_income_lower
FROM hd
LEFT JOIN ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY household_cnt DESC
LIMIT 100
