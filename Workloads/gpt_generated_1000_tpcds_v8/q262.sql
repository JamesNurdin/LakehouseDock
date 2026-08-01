WITH filtered_demo AS (
    SELECT *
    FROM tpcds.household_demographics
    TABLESAMPLE BERNOULLI (10)
    WHERE hd_income_band_sk IN (4, 6, 11, 17, 19)
      AND hd_vehicle_count >= 0
      AND hd_dep_count BETWEEN 1 AND 9
      AND hd_buy_potential IN ('High', 'Medium')
)
SELECT
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    CASE 
        WHEN hd.hd_vehicle_count = 0 THEN 'NoVehicle'
        WHEN hd.hd_vehicle_count = 1 THEN 'OneVehicle'
        ELSE 'MultipleVehicles'
    END AS vehicle_category,
    RANK() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY hd.hd_dep_count DESC) AS dep_count_rank,
    ROW_NUMBER() OVER (ORDER BY ib.ib_upper_bound ASC) AS overall_row_num,
    avg_tbl.avg_dep_cnt
FROM filtered_demo AS hd
JOIN tpcds.income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN LATERAL (
    SELECT AVG(hd2.hd_dep_count) AS avg_dep_cnt
    FROM tpcds.household_demographics AS hd2
    WHERE hd2.hd_income_band_sk = hd.hd_income_band_sk
) AS avg_tbl ON TRUE
WHERE ib.ib_lower_bound >= 30000
  AND ib.ib_upper_bound <= 130000
  AND ib.ib_income_band_sk <> 1
ORDER BY dep_count_rank, hd.hd_demo_sk
LIMIT 100
