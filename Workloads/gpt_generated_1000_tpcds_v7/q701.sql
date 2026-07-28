WITH hd_ib_high_potential AS (
    SELECT
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
        COUNT(*) AS household_cnt
    FROM tpcds.household_demographics AS hd
    JOIN tpcds.income_band AS ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential IN ('>10000', '5001-10000')
      AND hd.hd_dep_count >= 2
    GROUP BY hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
hd_ib_low_potential AS (
    SELECT
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
        COUNT(*) AS household_cnt
    FROM tpcds.household_demographics AS hd
    JOIN tpcds.income_band AS ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential = '0-500'
      AND hd.hd_vehicle_count = 0
    GROUP BY hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    hd_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    avg_vehicle_cnt,
    household_cnt
FROM hd_ib_high_potential
UNION ALL
SELECT
    hd_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    avg_vehicle_cnt,
    household_cnt
FROM hd_ib_low_potential
ORDER BY avg_vehicle_cnt DESC
