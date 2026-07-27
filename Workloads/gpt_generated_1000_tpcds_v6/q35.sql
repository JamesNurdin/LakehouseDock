WITH first AS (
  SELECT
    CAST(ib.ib_lower_bound AS VARCHAR) || '-' || CAST(ib.ib_upper_bound AS VARCHAR) AS income_range,
    AVG(hd.hd_vehicle_count) AS avg_vehicles,
    COUNT(*) AS household_cnt
  FROM household_demographics hd
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE hd.hd_dep_count >= 5
    AND hd.hd_vehicle_count >= 0
  GROUP BY CAST(ib.ib_lower_bound AS VARCHAR) || '-' || CAST(ib.ib_upper_bound AS VARCHAR)
),
second AS (
  SELECT
    CAST(ib.ib_lower_bound AS VARCHAR) || '-' || CAST(ib.ib_upper_bound AS VARCHAR) AS income_range,
    AVG(hd.hd_vehicle_count) AS avg_vehicles,
    COUNT(*) AS household_cnt
  FROM household_demographics hd
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE hd.hd_dep_count < 5
    AND hd.hd_vehicle_count < 0
  GROUP BY CAST(ib.ib_lower_bound AS VARCHAR) || '-' || CAST(ib.ib_upper_bound AS VARCHAR)
)
SELECT income_range, avg_vehicles, household_cnt
FROM first
UNION ALL
SELECT income_range, avg_vehicles, household_cnt
FROM second
ORDER BY avg_vehicles DESC
LIMIT 100
