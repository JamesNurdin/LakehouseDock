WITH avg_vehicle AS (
   SELECT ib.ib_income_band_sk,
          ib.ib_lower_bound,
          ib.ib_upper_bound,
          AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt
   FROM household_demographics hd
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE hd.hd_dep_count <= 3
     AND hd.hd_vehicle_count >= 0
   GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
high_potential AS (
   SELECT ib.ib_income_band_sk,
          ib.ib_lower_bound,
          ib.ib_upper_bound,
          COUNT(*) AS high_potential_cnt
   FROM household_demographics hd
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE hd.hd_buy_potential = 'HIGH'
   GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
unioned AS (
   SELECT av.ib_lower_bound,
          av.ib_upper_bound,
          'AVG_VEHICLE' AS metric,
          CAST(av.avg_vehicle_cnt AS double) AS metric_value
   FROM avg_vehicle av
   UNION ALL
   SELECT hp.ib_lower_bound,
          hp.ib_upper_bound,
          'HIGH_POTENTIAL_COUNT' AS metric,
          CAST(hp.high_potential_cnt AS double) AS metric_value
   FROM high_potential hp
)
SELECT DISTINCT
    u.ib_lower_bound,
    u.ib_upper_bound,
    u.metric,
    u.metric_value,
    (SELECT AVG(hd3.hd_vehicle_count)
       FROM household_demographics hd3
       WHERE hd3.hd_vehicle_count >= 0) AS global_avg_vehicle
FROM unioned u
WHERE u.metric_value IS NOT NULL
ORDER BY u.ib_lower_bound, u.metric
LIMIT 100
