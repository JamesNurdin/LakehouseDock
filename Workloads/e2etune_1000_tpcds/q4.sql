WITH agg AS (
  SELECT
    sm.sm_contract,
    t.t_shift,
    COUNT(*) AS household_cnt,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
    SUM(CASE WHEN hd.hd_buy_potential = '>10000' THEN 1 ELSE 0 END) AS high_buy_potential_cnt
  FROM household_demographics hd
  INNER JOIN ship_mode sm ON true
  INNER JOIN time_dim t ON true
  WHERE hd.hd_vehicle_count >= 2
    AND hd.hd_buy_potential IN ('1001-5000', '>10000')
    AND sm.sm_contract = 'YvxVaJI10'
    AND t.t_shift = 'Evening'
  GROUP BY sm.sm_contract, t.t_shift
  HAVING COUNT(*) >= 5
)
SELECT
  sm_contract,
  t_shift,
  household_cnt,
  avg_vehicle_cnt,
  high_buy_potential_cnt,
  ROW_NUMBER() OVER (PARTITION BY sm_contract ORDER BY avg_vehicle_cnt DESC) AS rn
FROM agg
ORDER BY avg_vehicle_cnt DESC
LIMIT 10
