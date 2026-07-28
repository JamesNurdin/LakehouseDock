WITH avg_vehicle AS (
   SELECT avg(hd_vehicle_count) AS avg_vehicle
   FROM household_demographics
)
SELECT
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    CASE WHEN ib.ib_upper_bound >= 150000 THEN 'High' ELSE 'Medium' END AS income_category,
    row_number() OVER (
        PARTITION BY CASE WHEN ib.ib_upper_bound >= 150000 THEN 'High' ELSE 'Medium' END
        ORDER BY hd.hd_vehicle_count DESC
    ) AS vehicle_rank,
    av.avg_vehicle
FROM household_demographics hd
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
CROSS JOIN avg_vehicle av
WHERE hd.hd_vehicle_count >= 1
  AND hd.hd_dep_count <= 3
  AND ib.ib_lower_bound >= 30000
  AND ib.ib_upper_bound <= 180000
  AND NOT EXISTS (
        SELECT 1
        FROM income_band ib2
        WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk
          AND ib2.ib_upper_bound > 150000
      )
ORDER BY income_category, vehicle_rank
LIMIT 100
