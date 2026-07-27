WITH a AS (
  SELECT
    hd.hd_demo_sk,
    hd.hd_vehicle_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    (hd.hd_vehicle_count * 1.0) / NULLIF(ib.ib_upper_bound - ib.ib_lower_bound + 1, 0) AS vehicle_income_ratio,
    ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY hd.hd_demo_sk) AS rn
  FROM household_demographics hd
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE ib.ib_income_band_sk IN (10, 12, 13)
    AND hd.hd_vehicle_count >= 0
),

b AS (
  SELECT
    hd.hd_demo_sk,
    hd.hd_vehicle_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    (hd.hd_vehicle_count * 1.0) / NULLIF(ib.ib_upper_bound - ib.ib_lower_bound + 1, 0) AS vehicle_income_ratio,
    ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY hd.hd_demo_sk DESC) AS rn
  FROM household_demographics hd
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE ib.ib_upper_bound BETWEEN 50000 AND 150000
    AND hd.hd_dep_count > 2
)

SELECT
  demo_sk,
  vehicle_count,
  lower_bound,
  upper_bound,
  vehicle_income_ratio,
  rn
FROM (
  SELECT
    hd_demo_sk AS demo_sk,
    hd_vehicle_count AS vehicle_count,
    ib_lower_bound AS lower_bound,
    ib_upper_bound AS upper_bound,
    vehicle_income_ratio,
    rn
  FROM a

  UNION ALL

  SELECT
    hd_demo_sk AS demo_sk,
    hd_vehicle_count AS vehicle_count,
    ib_lower_bound AS lower_bound,
    ib_upper_bound AS upper_bound,
    vehicle_income_ratio,
    rn
  FROM b
) combined
ORDER BY vehicle_income_ratio DESC, demo_sk
LIMIT 100
