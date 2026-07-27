WITH max_upper AS (
    SELECT max(ib_upper_bound) AS max_ub
    FROM income_band
)
SELECT
    hd.hd_buy_potential AS buy_potential,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
    AVG(hd.hd_dep_count) AS avg_dep_count,
    mu.max_ub AS overall_max_upper_bound
FROM household_demographics hd
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN max_upper mu
    ON 1 = 1
WHERE ib.ib_upper_bound >= 130000
  AND hd.hd_buy_potential LIKE '%>10000%'
  AND EXISTS (
        SELECT 1
        FROM income_band ib2
        WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk
          AND ib2.ib_lower_bound > 50000
    )
GROUP BY hd.hd_buy_potential, mu.max_ub

UNION ALL

SELECT
    hd.hd_buy_potential AS buy_potential,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
    AVG(hd.hd_dep_count) AS avg_dep_count,
    mu.max_ub AS overall_max_upper_bound
FROM household_demographics hd
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN max_upper mu
    ON 1 = 1
WHERE ib.ib_upper_bound <= 100000
  AND hd.hd_buy_potential IN ('0-500', '501-1000')
  AND NOT EXISTS (
        SELECT 1
        FROM income_band ib2
        WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk
          AND ib2.ib_lower_bound > 50000
    )
GROUP BY hd.hd_buy_potential, mu.max_ub
LIMIT 100
