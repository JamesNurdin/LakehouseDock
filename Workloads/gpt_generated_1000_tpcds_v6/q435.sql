WITH first_set AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        CASE
            WHEN ib.ib_upper_bound <= 50000 THEN 'Low'
            WHEN ib.ib_upper_bound <= 150000 THEN 'Mid'
            ELSE 'High'
        END AS income_category,
        hd.hd_vehicle_count,
        hd.hd_buy_potential,
        (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY hd.hd_vehicle_count DESC) AS rn
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count >= 0
      AND ib.ib_lower_bound >= 100000
),
second_set AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        CASE
            WHEN ib.ib_upper_bound <= 50000 THEN 'Low'
            WHEN ib.ib_upper_bound <= 150000 THEN 'Mid'
            ELSE 'High'
        END AS income_category,
        hd.hd_vehicle_count,
        hd.hd_buy_potential,
        (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY hd.hd_vehicle_count DESC) AS rn
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count < 0
      AND ib.ib_upper_bound <= 80000
)
SELECT *
FROM (
    SELECT * FROM first_set
    UNION ALL
    SELECT * FROM second_set
) AS combined
ORDER BY income_category, rn DESC
LIMIT 100
