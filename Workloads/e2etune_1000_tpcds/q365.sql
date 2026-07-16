WITH band_stats AS (
  SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    (ib.ib_upper_bound - ib.ib_lower_bound + 1) AS band_width
  FROM income_band ib
  WHERE ib.ib_upper_bound > 20000
),
agg AS (
  SELECT
    sm.sm_type,
    COUNT(*) AS ship_mode_count,
    SUM(bs.band_width) AS total_band_width,
    AVG(LENGTH(sm.sm_ship_mode_id)) AS avg_ship_id_len
  FROM ship_mode sm
  JOIN band_stats bs
    ON bs.ib_income_band_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_contract LIKE '%I%'
  GROUP BY sm.sm_type
  HAVING COUNT(*) >= 1
)
SELECT
  sm_type,
  ship_mode_count,
  total_band_width,
  avg_ship_id_len,
  RANK() OVER (ORDER BY total_band_width DESC) AS rank_by_width
FROM agg
ORDER BY rank_by_width
LIMIT 5
