WITH hd_agg AS (
    SELECT
        hd_income_band_sk,
        COUNT(*) AS household_cnt,
        SUM(hd_dep_count) AS total_dep_count,
        AVG(hd_vehicle_count) AS avg_vehicle_count
    FROM household_demographics
    WHERE hd_buy_potential IN ('5001-10000', '1001-5000')
      AND hd_dep_count >= 5
    GROUP BY hd_income_band_sk
    HAVING COUNT(*) > 5
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ha.household_cnt,
    ha.total_dep_count,
    ha.avg_vehicle_count
FROM hd_agg AS ha
JOIN income_band AS ib
  ON ha.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_lower_bound >= 10000
  AND ib.ib_upper_bound <= 160000
  AND ha.avg_vehicle_count > (SELECT AVG(ib_upper_bound) FROM income_band)
  AND NOT EXISTS (
        SELECT 1
        FROM household_demographics hd2
        WHERE hd2.hd_income_band_sk = ib.ib_income_band_sk
          AND hd2.hd_buy_potential = 'Unknown'
    )
ORDER BY ib.ib_lower_bound ASC
