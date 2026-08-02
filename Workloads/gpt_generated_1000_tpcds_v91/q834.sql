WITH raw_data AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM tpcds.household_demographics hd
    LEFT JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_dep_count >= 1
      AND hd.hd_vehicle_count > 0
      AND ib.ib_lower_bound > 50000
      AND ib.ib_upper_bound < 150000

    UNION ALL

    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM tpcds.household_demographics hd
    LEFT JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_dep_count = 0
      AND hd.hd_vehicle_count >= 0
      AND ib.ib_lower_bound >= 0
      AND ib.ib_upper_bound > 100000
),
per_band AS (
    SELECT
        hd_income_band_sk,
        MAX(ib_lower_bound) AS ib_lower_bound,
        MAX(ib_upper_bound) AS ib_upper_bound,
        SUM(hd_vehicle_count) AS total_vehicle,
        SUM(hd_dep_count) AS total_dep,
        COUNT(*) AS household_count
    FROM raw_data
    WHERE hd_vehicle_count IS NOT NULL
    GROUP BY hd_income_band_sk
),
final AS (
    SELECT
        pb.hd_income_band_sk,
        pb.ib_lower_bound,
        pb.ib_upper_bound,
        pb.total_vehicle,
        pb.total_dep,
        pb.household_count,
        (SELECT COUNT(*)
         FROM tpcds.household_demographics hd2
         WHERE hd2.hd_income_band_sk = pb.hd_income_band_sk) AS total_households_in_band,
        (SELECT AVG(hd_vehicle_count)
         FROM tpcds.household_demographics hd2
         WHERE hd2.hd_income_band_sk = pb.hd_income_band_sk) AS avg_vehicle_per_band
    FROM per_band pb
    WHERE pb.total_dep > 5
      AND EXISTS (
          SELECT 1
          FROM tpcds.household_demographics hd3
          WHERE hd3.hd_income_band_sk = pb.hd_income_band_sk
            AND hd3.hd_vehicle_count > 2
      )
      AND pb.total_vehicle > (
          SELECT AVG(hd_vehicle_count)
          FROM tpcds.household_demographics
      )
)
SELECT
    hd_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_vehicle,
    total_dep,
    household_count,
    total_households_in_band,
    avg_vehicle_per_band
FROM final
ORDER BY total_vehicle DESC
LIMIT 10
