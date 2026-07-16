WITH filtered_store AS (
  SELECT *
  FROM store
  WHERE s_rec_start_date <= CURRENT_DATE
    AND (s_rec_end_date IS NULL OR s_rec_end_date >= CURRENT_DATE)
    AND s_floor_space > 0
    AND s_tax_percentage > 0
)
SELECT
  sm.sm_carrier,
  sm.sm_type,
  COUNT(DISTINCT s.s_store_sk) AS store_cnt,
  SUM(s.s_floor_space) AS total_floor_space,
  AVG(s.s_tax_percentage) AS avg_tax_pct,
  RANK() OVER (ORDER BY SUM(s.s_floor_space) DESC) AS floor_space_rank
FROM ship_mode sm
JOIN filtered_store s
  ON SUBSTR(sm.sm_type, 1, 1) = SUBSTR(s.s_state, 1, 1)
WHERE sm.sm_type IN ('EXPRESS', 'OVERNIGHT', 'TWO DAY')
GROUP BY sm.sm_carrier, sm.sm_type
HAVING COUNT(DISTINCT s.s_store_sk) >= 5
ORDER BY floor_space_rank
LIMIT 10
