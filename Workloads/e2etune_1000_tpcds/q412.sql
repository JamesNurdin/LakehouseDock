WITH store_agg AS (
  SELECT s_state,
         SUM(s_floor_space) AS total_floor_space,
         AVG(s_tax_percentage) AS avg_tax_pct,
         COUNT(DISTINCT s_store_sk) AS store_cnt
  FROM store
  WHERE s_state IN ('CA', 'TX', 'NY')
    AND s_floor_space IS NOT NULL
  GROUP BY s_state
), household_agg AS (
  SELECT hd_buy_potential,
         COUNT(*) AS household_cnt,
         AVG(hd_vehicle_count) AS avg_vehicle_cnt,
         AVG(hd_dep_count) AS avg_dep_cnt
  FROM household_demographics
  WHERE hd_buy_potential IN ('1001-5000', '>10000')
    AND hd_income_band_sk BETWEEN 2 AND 5
  GROUP BY hd_buy_potential
)
SELECT s.s_state,
       h.hd_buy_potential,
       s.total_floor_space,
       s.avg_tax_pct,
       s.store_cnt,
       h.household_cnt,
       h.avg_vehicle_cnt,
       h.avg_dep_cnt
FROM store_agg s
JOIN household_agg h
  ON 1 = 1
ORDER BY s.total_floor_space DESC, h.household_cnt DESC
LIMIT 100
