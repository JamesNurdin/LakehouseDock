WITH full_join AS (
  SELECT
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
  FROM household_demographics hd
  FULL OUTER JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE (
    hd.hd_dep_count > 2 OR hd.hd_dep_count IS NULL
  )
    AND (
    hd.hd_vehicle_count <= 5 OR hd.hd_vehicle_count IS NULL
  )
    AND (
    ib.ib_upper_bound BETWEEN 40000 AND 100000 OR ib.ib_upper_bound IS NULL
  )
),
intersect_keys AS (
  SELECT hd.hd_income_band_sk AS band_sk
  FROM household_demographics hd
  WHERE hd.hd_dep_count = 4
  INTERSECT
  SELECT ib.ib_income_band_sk
  FROM income_band ib
  WHERE ib.ib_lower_bound > 80000
),
union_sets AS (
  SELECT hd.hd_income_band_sk AS band_sk,
         hd.hd_buy_potential AS category,
         hd.hd_dep_count AS dep_cnt
  FROM household_demographics hd
  WHERE hd.hd_vehicle_count = 1
  UNION
  SELECT ib.ib_income_band_sk,
         CAST('UNKNOWN' AS varchar),
         NULL
  FROM income_band ib
  WHERE ib.ib_upper_bound = 60000
),
aggregated AS (
  SELECT
    fj.hd_buy_potential,
    fj.hd_dep_count,
    COUNT(*) AS cnt,
    SUM(fj.hd_vehicle_count) AS total_vehicles,
    AVG(fj.ib_lower_bound) AS avg_lower,
    MIN(fj.ib_upper_bound) AS min_upper,
    MAX(fj.ib_upper_bound) AS max_upper
  FROM full_join fj
  WHERE EXISTS (
    SELECT 1 FROM intersect_keys ik WHERE ik.band_sk = fj.hd_income_band_sk
  )
    AND fj.hd_income_band_sk IN (SELECT band_sk FROM union_sets)
  GROUP BY GROUPING SETS (
    (fj.hd_buy_potential, fj.hd_dep_count),
    (fj.hd_buy_potential),
    (fj.hd_dep_count),
    ()
  )
)
SELECT *
FROM aggregated
ORDER BY cnt DESC
LIMIT 100
