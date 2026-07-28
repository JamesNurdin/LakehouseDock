WITH hd_income AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS household_cnt,
        SUM(hd.hd_vehicle_count) AS total_vehicles,
        AVG(hd.hd_vehicle_count) AS avg_vehicles,
        SUM(hd.hd_dep_count) AS total_dependents
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential <> 'Unknown'
      AND hd.hd_dep_count BETWEEN 2 AND 8
      AND ib.ib_lower_bound >= 10000
      AND ib.ib_upper_bound <= 200000
    GROUP BY CUBE (ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound)
)
SELECT
    hi.ib_income_band_sk,
    hi.ib_lower_bound,
    hi.ib_upper_bound,
    hi.household_cnt,
    hi.total_vehicles,
    hi.avg_vehicles,
    hi.total_dependents,
    RANK() OVER (ORDER BY hi.total_vehicles DESC) AS vehicle_rank,
    CASE
        WHEN hi.household_cnt > (SELECT AVG(household_cnt) FROM hd_income) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS cnt_category
FROM hd_income hi
WHERE NOT EXISTS (
        SELECT 1
        FROM household_demographics hd2
        WHERE hd2.hd_income_band_sk = hi.ib_income_band_sk
          AND hd2.hd_buy_potential = 'Unknown'
    )
  AND hi.total_vehicles > (SELECT AVG(total_vehicles) FROM hd_income)
ORDER BY hi.ib_income_band_sk ASC NULLS LAST, hi.household_cnt DESC
