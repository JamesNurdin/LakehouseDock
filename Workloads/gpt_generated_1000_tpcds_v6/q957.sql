WITH ib_ranges AS (
    SELECT ib_income_band_sk,
           ib_lower_bound,
           ib_upper_bound
    FROM income_band
    WHERE ib_upper_bound > 50000
)
SELECT DISTINCT
    ib_lower_bound,
    ib_upper_bound,
    avg_vehicle_cnt,
    buy_potential_category
FROM (
    SELECT
        r.ib_lower_bound,
        r.ib_upper_bound,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
        'LowBuyPotential' AS buy_potential_category
    FROM household_demographics hd
    JOIN ib_ranges r
        ON hd.hd_income_band_sk = r.ib_income_band_sk
    WHERE hd.hd_buy_potential = '0-500'
      AND hd.hd_dep_count <= 3
      AND EXISTS (
          SELECT 1
          FROM income_band ib2
          WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk
            AND ib2.ib_upper_bound > 100000
      )
    GROUP BY r.ib_lower_bound, r.ib_upper_bound

    UNION ALL

    SELECT
        r.ib_lower_bound,
        r.ib_upper_bound,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
        'MidBuyPotential' AS buy_potential_category
    FROM household_demographics hd
    JOIN ib_ranges r
        ON hd.hd_income_band_sk = r.ib_income_band_sk
    WHERE hd.hd_buy_potential = '1001-5000'
      AND hd.hd_dep_count > 3
      AND hd.hd_vehicle_count IS NOT NULL
    GROUP BY r.ib_lower_bound, r.ib_upper_bound
) AS combined
ORDER BY ib_lower_bound, ib_upper_bound DESC
LIMIT 100
