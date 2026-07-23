WITH filtered_households AS (
  SELECT
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    regexp_extract(hd.hd_buy_potential, '^([0-9]+)-([0-9]+)$', 1) AS buy_low_str,
    regexp_extract(hd.hd_buy_potential, '^([0-9]+)-([0-9]+)$', 2) AS buy_high_str
  FROM household_demographics hd
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE regexp_like(hd.hd_buy_potential, '^[0-9]+-[0-9]+$')
    AND hd.hd_buy_potential LIKE '5%'
)

SELECT
  CONCAT('Band ', CAST(fh.ib_lower_bound AS varchar), '-', CAST(fh.ib_upper_bound AS varchar)) AS band_label,
  MIN(fh.ib_lower_bound) AS lower_bound,
  MAX(fh.ib_upper_bound) AS upper_bound,
  COUNT(*) AS household_cnt,
  AVG(fh.hd_vehicle_count) AS avg_vehicle_cnt,
  (SELECT AVG(hd_vehicle_count) FROM household_demographics) AS overall_avg_vehicle_cnt,
  AVG(CAST(fh.buy_low_str AS integer)) AS avg_buy_low,
  SUM(CASE WHEN CAST(fh.buy_high_str AS integer) > 5000 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS pct_buy_high_gt_5000
FROM filtered_households fh
WHERE EXISTS (
  SELECT 1
  FROM household_demographics hd2
  WHERE hd2.hd_income_band_sk = fh.hd_income_band_sk
    AND hd2.hd_buy_potential = '0-500'
)
GROUP BY fh.ib_lower_bound, fh.ib_upper_bound
HAVING COUNT(*) > 5
ORDER BY household_cnt DESC
LIMIT 100
