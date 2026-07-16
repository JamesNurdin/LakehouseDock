WITH agg AS (
  SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    COUNT(*) AS household_cnt,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
    SUM(hd.hd_dep_count) AS total_dependents
  FROM household_demographics hd
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE hd.hd_buy_potential IN ('1001-5000', '5001-10000')
    AND hd.hd_dep_count >= 2
    AND ib.ib_lower_bound >= 20000
  GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential
  HAVING COUNT(*) > 5
)
SELECT
  agg.ib_income_band_sk,
  agg.ib_lower_bound,
  agg.ib_upper_bound,
  agg.hd_buy_potential,
  agg.household_cnt,
  agg.avg_vehicle_cnt,
  agg.total_dependents,
  RANK() OVER (ORDER BY agg.avg_vehicle_cnt DESC) AS vehicle_cnt_rank
FROM agg
ORDER BY agg.avg_vehicle_cnt DESC
LIMIT 20
