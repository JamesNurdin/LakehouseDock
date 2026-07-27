WITH filtered AS (
  SELECT
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    regexp_extract(hd.hd_buy_potential, '(\\d+)-', 1) AS range_low_str,
    regexp_extract(hd.hd_buy_potential, '-(\\d+)', 1) AS range_high_str
  FROM household_demographics hd
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE regexp_like(hd.hd_buy_potential, '^[0-9]+-[0-9]+$')
    AND hd.hd_buy_potential LIKE '%1000%'
)
SELECT
  concat('Band ', cast(ib_income_band_sk AS varchar), ': ', cast(ib_lower_bound AS varchar), '-', cast(ib_upper_bound AS varchar)) AS income_band_label,
  count(*) AS households,
  avg(hd_vehicle_count) AS avg_vehicles,
  sum(hd_dep_count) AS total_dependents,
  CASE
    WHEN avg(hd_vehicle_count) > 2 THEN 'HighVehicle'
    ELSE 'LowVehicle'
  END AS vehicle_category
FROM filtered
GROUP BY
  ib_income_band_sk,
  ib_lower_bound,
  ib_upper_bound
ORDER BY households DESC
LIMIT 100
