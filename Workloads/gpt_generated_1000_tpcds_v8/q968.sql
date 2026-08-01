WITH
  sampled_hd AS (
    SELECT *
    FROM household_demographics
    TABLESAMPLE BERNOULLI (10)
    WHERE hd_dep_count >= 1
      AND hd_vehicle_count >= 0
      AND hd_buy_potential IN ('HIGH', 'MEDIUM')
      AND hd_income_band_sk BETWEEN 4 AND 20
      AND hd_demo_sk NOT IN (0)
  ),
  joined AS (
    SELECT
      hd.hd_demo_sk,
      hd.hd_income_band_sk,
      hd.hd_buy_potential,
      hd.hd_dep_count,
      hd.hd_vehicle_count,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    FROM sampled_hd hd
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound <= 200000
      AND ib.ib_lower_bound >= 40000
  ),
  agg_by_band AS (
    SELECT
      j.hd_income_band_sk,
      j.ib_lower_bound,
      j.ib_upper_bound,
      COUNT(*) AS household_cnt,
      SUM(j.hd_vehicle_count) AS total_vehicles,
      AVG(j.hd_dep_count) AS avg_dep,
      MIN(j.hd_vehicle_count) AS min_veh,
      MAX(j.hd_vehicle_count) AS max_veh,
      (
        SELECT COUNT(*)
        FROM household_demographics h_full
        WHERE h_full.hd_income_band_sk = j.hd_income_band_sk
      ) AS total_in_band_all
    FROM joined j
    GROUP BY j.hd_income_band_sk, j.ib_lower_bound, j.ib_upper_bound
  ),
  ranked AS (
    SELECT
      a.*, 
      RANK() OVER (ORDER BY a.household_cnt DESC) AS income_band_rank,
      SUM(a.total_vehicles) OVER (PARTITION BY a.ib_lower_bound) AS sum_veh_by_lower_bound
    FROM agg_by_band a
  ),
  key_diff AS (
    SELECT hd_demo_sk
    FROM sampled_hd
    WHERE hd_vehicle_count > 2
    EXCEPT
    SELECT hd_demo_sk
    FROM sampled_hd
    WHERE hd_vehicle_count <= 2
  ),
  set_union AS (
    SELECT hd_income_band_sk, household_cnt
    FROM ranked
    WHERE income_band_rank <= 5
    UNION ALL
    SELECT hd_income_band_sk, household_cnt
    FROM ranked
    WHERE total_vehicles > 10
  ),
  cross_dim AS (
    SELECT v.val, s.hd_income_band_sk
    FROM (VALUES (1), (2)) AS v(val)
    CROSS JOIN (SELECT DISTINCT hd_income_band_sk FROM sampled_hd) AS s
  )
SELECT
  r.hd_income_band_sk,
  r.ib_lower_bound,
  r.ib_upper_bound,
  r.household_cnt,
  r.total_vehicles,
  r.avg_dep,
  r.min_veh,
  r.max_veh,
  r.total_in_band_all,
  r.income_band_rank,
  r.sum_veh_by_lower_bound,
  kd.hd_demo_sk AS diff_demo_sk,
  cd.val AS dim_val,
  su.household_cnt AS union_household_cnt
FROM ranked r
LEFT JOIN (SELECT hd_demo_sk FROM key_diff LIMIT 1) kd ON true
LEFT JOIN cross_dim cd ON cd.hd_income_band_sk = r.hd_income_band_sk
LEFT JOIN set_union su ON su.hd_income_band_sk = r.hd_income_band_sk
WHERE r.ib_upper_bound BETWEEN 50000 AND 200000
  AND r.ib_lower_bound >= 40000
LIMIT 100
