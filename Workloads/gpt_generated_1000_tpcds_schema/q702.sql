WITH filtered_hd AS (
    SELECT hd_demo_sk,
           hd_income_band_sk,
           hd_buy_potential,
           hd_dep_count,
           hd_vehicle_count
    FROM household_demographics
    WHERE hd_vehicle_count > 0
      AND hd_dep_count BETWEEN 1 AND 7
      AND hd_buy_potential IN ('High', 'Medium')
),
anti AS (
    SELECT hd_demo_sk
    FROM household_demographics
    WHERE hd_vehicle_count < 0
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT fh.hd_demo_sk) AS distinct_demo_cnt,
    COUNT(DISTINCT fh.hd_vehicle_count) AS distinct_vehicle_cnt,
    SUM(fh.hd_vehicle_count) AS total_vehicles,
    AVG(fh.hd_dep_count) AS avg_dependents,
    CASE
        WHEN ib.ib_upper_bound > 150000 THEN 'High Income'
        ELSE 'Mid/Low Income'
    END AS income_category,
    lt.max_vehicle
FROM filtered_hd fh
RIGHT JOIN income_band ib
    ON fh.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN LATERAL (
    SELECT MAX(hd_vehicle_count) AS max_vehicle
    FROM household_demographics hd2
    WHERE hd2.hd_income_band_sk = ib.ib_income_band_sk
) lt ON TRUE
WHERE fh.hd_demo_sk NOT IN (SELECT hd_demo_sk FROM anti)
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE WHEN ib.ib_upper_bound > 150000 THEN 'High Income' ELSE 'Mid/Low Income' END,
    lt.max_vehicle
ORDER BY ib.ib_income_band_sk
LIMIT 100
