WITH per_band AS (
  SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(*) AS household_cnt,
    SUM(hd.hd_dep_count) AS total_dep,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
    SUM(CASE WHEN hd.hd_buy_potential = 'High' THEN 1 ELSE 0 END) AS high_potential_cnt
  FROM household_demographics hd
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE hd.hd_dep_count BETWEEN 1 AND 8
    AND hd.hd_vehicle_count >= 1
    AND ib.ib_lower_bound >= 20000
    AND ib.ib_upper_bound <= 150000
  GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
  COUNT(*) AS qualifying_bands,
  AVG(avg_vehicle_cnt) AS avg_vehicle_across_bands,
  SUM(total_dep) AS sum_total_dep,
  AVG(total_dep * 1.0 / household_cnt) AS avg_dep_per_household_overall
FROM per_band
WHERE household_cnt >= 10
  AND high_potential_cnt > 0
  AND avg_vehicle_cnt > 1.5
  AND (total_dep * 1.0 / household_cnt) < 5
HAVING AVG(avg_vehicle_cnt) > 2
ORDER BY avg_vehicle_across_bands DESC
LIMIT 100
