WITH hd_agg AS (
    SELECT
        hd.hd_income_band_sk,
        COUNT(*) AS household_cnt,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
        SUM(hd.hd_vehicle_count) AS sum_vehicle_cnt
    FROM tpcds.household_demographics hd
    WHERE hd.hd_vehicle_count >= 0
      AND hd.hd_dep_count <= 5
      AND hd.hd_income_band_sk IN (
          SELECT ib.ib_income_band_sk
          FROM tpcds.income_band ib
          WHERE ib.ib_upper_bound <= 130000
      )
    GROUP BY hd.hd_income_band_sk
),
final_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd_agg.household_cnt,
        hd_agg.avg_vehicle_cnt,
        hd_agg.sum_vehicle_cnt
    FROM hd_agg
    JOIN tpcds.income_band ib
        ON hd_agg.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 60000
      AND ib.ib_upper_bound <= 150000
      AND hd_agg.household_cnt > 10
      AND hd_agg.avg_vehicle_cnt < 3
)
SELECT
    COUNT(*) AS num_income_bands,
    AVG(household_cnt) AS avg_households_per_band,
    MAX(sum_vehicle_cnt) AS max_total_vehicles
FROM final_agg
ORDER BY avg_households_per_band DESC
LIMIT 100
