WITH hd_sm_agg AS (
  SELECT
    hd.hd_buy_potential,
    sm.sm_type,
    COUNT(*) AS cross_count,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
    SUM(CASE WHEN hd.hd_dep_count = 0 THEN 1 ELSE 0 END) AS zero_dep_households
  FROM household_demographics hd
  JOIN ship_mode sm
    ON hd.hd_vehicle_count = sm.sm_ship_mode_sk
  WHERE hd.hd_income_band_sk BETWEEN 2 AND 5
    AND sm.sm_carrier IN ('UPS','FedEx')
  GROUP BY hd.hd_buy_potential, sm.sm_type
  HAVING COUNT(*) > 10
)
SELECT
  hd_buy_potential,
  sm_type,
  cross_count,
  avg_vehicle_cnt,
  zero_dep_households,
  RANK() OVER (PARTITION BY hd_buy_potential ORDER BY cross_count DESC) AS rank_in_potential
FROM hd_sm_agg
ORDER BY cross_count DESC
LIMIT 100
