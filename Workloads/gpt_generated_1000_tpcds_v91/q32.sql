WITH filtered_hd AS (
    SELECT hd_demo_sk
    FROM tpcds.household_demographics
    WHERE hd_vehicle_count > 1
      AND hd_dep_count <= 5
      AND hd_buy_potential IS NOT NULL
),
filtered_ib AS (
    SELECT ib_income_band_sk
    FROM tpcds.income_band
    WHERE ib_lower_bound >= 20000
      AND ib_upper_bound <= 150000
),
intersected_keys AS (
    SELECT hd_demo_sk FROM filtered_hd
    INTERSECT
    SELECT hd_demo_sk FROM tpcds.household_demographics
    WHERE hd_income_band_sk IN (SELECT ib_income_band_sk FROM filtered_ib)
)
SELECT
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(*) AS household_cnt,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
    SUM(hd.hd_dep_count) AS total_dependents,
    MIN(hd.hd_vehicle_count) AS min_vehicle_count,
    MAX(hd.hd_dep_count) AS max_dependents
FROM tpcds.household_demographics hd
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN intersected_keys ik
  ON hd.hd_demo_sk = ik.hd_demo_sk
WHERE hd.hd_vehicle_count > 1
  AND hd.hd_dep_count <= 5
  AND ib.ib_lower_bound >= 20000
  AND ib.ib_upper_bound <= 150000
GROUP BY hd.hd_buy_potential, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY household_cnt DESC
LIMIT 100
