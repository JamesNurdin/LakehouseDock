WITH band_stats AS (
  SELECT
    sm.sm_type,
    sm.sm_carrier,
    sm.sm_code,
    COUNT(ib.ib_income_band_sk) AS band_count,
    AVG(ib.ib_lower_bound) AS avg_lower,
    MAX(ib.ib_upper_bound) AS max_upper
  FROM income_band ib
  JOIN ship_mode sm ON TRUE
  WHERE sm.sm_type IN ('EXPRESS', 'OVERNIGHT', 'TWO DAY')
    AND sm.sm_code IN ('AIR', 'SURFACE')
    AND ib.ib_upper_bound <= 40000
  GROUP BY sm.sm_type, sm.sm_carrier, sm.sm_code
  HAVING COUNT(*) >= 2
)
SELECT
  sm_type,
  sm_carrier,
  sm_code,
  band_count,
  avg_lower,
  max_upper,
  RANK() OVER (PARTITION BY sm_carrier ORDER BY avg_lower DESC) AS rank_avg_lower
FROM band_stats
ORDER BY sm_carrier, rank_avg_lower
LIMIT 50
