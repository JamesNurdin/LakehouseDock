WITH filtered_demo AS (
    SELECT hd.hd_demo_sk,
           hd.hd_income_band_sk,
           hd.hd_buy_potential,
           hd.hd_dep_count,
           hd.hd_vehicle_count
    FROM tpcds.household_demographics hd
    WHERE hd.hd_buy_potential = '1001-5000'
      AND hd.hd_dep_count >= 2
      AND hd.hd_vehicle_count <= 3
      AND NOT EXISTS (
          SELECT 1
          FROM tpcds.income_band ib_ex
          WHERE ib_ex.ib_income_band_sk = hd.hd_income_band_sk
            AND ib_ex.ib_lower_bound = 0
      )
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(fd.hd_demo_sk) AS household_count,
    SUM(fd.hd_vehicle_count) AS total_vehicles,
    AVG(fd.hd_dep_count) AS avg_dependents,
    MIN(fd.hd_dep_count) AS min_dependents,
    MAX(fd.hd_dep_count) AS max_dependents,
    ROW_NUMBER() OVER (ORDER BY COUNT(fd.hd_demo_sk) DESC) AS row_num
FROM filtered_demo fd
JOIN tpcds.income_band ib
  ON fd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_lower_bound >= 20001
  AND ib.ib_upper_bound <= 200000
  AND ib.ib_income_band_sk <> 14
  AND fd.hd_buy_potential <> 'Unknown'
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
HAVING COUNT(fd.hd_demo_sk) > 10
   AND AVG(fd.hd_dep_count) > 2
ORDER BY household_count DESC
LIMIT 100
