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
    regexp_extract(hd.hd_buy_potential, '(\\d+)-\\d+', 1) AS lower_range,
    regexp_extract(hd.hd_buy_potential, '-(\\d+)', 1) AS upper_range,
    CASE
      WHEN regexp_like(hd.hd_buy_potential, '^>') THEN 'high'
      WHEN hd.hd_buy_potential = 'Unknown' THEN 'unknown'
      ELSE 'normal'
    END AS potential_category
  FROM household_demographics hd
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE hd.hd_buy_potential LIKE '%-%'
    AND ib.ib_upper_bound >= 50000
)
SELECT
  filtered.ib_income_band_sk,
  CONCAT('Band ', CAST(filtered.ib_lower_bound AS VARCHAR), '-', CAST(filtered.ib_upper_bound AS VARCHAR)) AS income_band_label,
  COUNT(*) AS households,
  AVG(CAST(filtered.lower_range AS DOUBLE)) AS avg_lower_buy_range,
  AVG(CAST(filtered.upper_range AS DOUBLE)) AS avg_upper_buy_range,
  SUM(filtered.hd_vehicle_count) AS total_vehicles,
  SUM(CASE WHEN filtered.potential_category = 'high' THEN 1 ELSE 0 END) AS high_potential_households
FROM filtered
GROUP BY filtered.ib_income_band_sk, filtered.ib_lower_bound, filtered.ib_upper_bound
ORDER BY households DESC
LIMIT 10
