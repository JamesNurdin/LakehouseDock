WITH filtered_hd AS (
    SELECT
        hd_demo_sk,
        hd_income_band_sk,
        hd_buy_potential,
        hd_dep_count,
        hd_vehicle_count
    FROM tpcds.household_demographics
    WHERE hd_vehicle_count BETWEEN 1 AND 4
      AND hd_dep_count >= 5
      AND hd_buy_potential IN ('HIGH', 'MEDIUM')
      AND hd_demo_sk IN (6, 10, 13, 18, 20)
      AND hd_income_band_sk IS NOT NULL
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(fd.hd_demo_sk) AS household_count,
    AVG(fd.hd_vehicle_count) AS avg_vehicle_count,
    SUM(fd.hd_dep_count) AS total_dependents,
    MIN(fd.hd_vehicle_count) AS min_vehicle_count,
    MAX(fd.hd_vehicle_count) AS max_vehicle_count
FROM filtered_hd fd
LEFT OUTER JOIN tpcds.income_band ib
    ON fd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_lower_bound >= 50000
  AND ib.ib_upper_bound <= 170000
  AND (ib.ib_income_band_sk = 5 OR ib.ib_income_band_sk = 14)
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY household_count DESC
LIMIT 100
