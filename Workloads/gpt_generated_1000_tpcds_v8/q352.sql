/*
Goal: Identify household buy‑potential categories and income‑band statistics while exercising advanced string functions, distinct selection, CTE aggregation, HAVING, anti‑joins, scalar subquery comparisons, and a UNION‑DISTINCT of two analytical result sets.
*/
WITH hd_agg AS (
    SELECT
        hd.hd_income_band_sk,
        COUNT(*)                                    AS cnt,
        AVG(hd.hd_vehicle_count)                    AS avg_vehicle,
        SUM(CASE WHEN regexp_like(hd.hd_buy_potential, '^high|medium') THEN 1 ELSE 0 END) AS high_mid_cnt
    FROM household_demographics hd
    GROUP BY hd.hd_income_band_sk
    HAVING COUNT(*) > 5
)
SELECT DISTINCT
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    hd.hd_vehicle_count
FROM household_demographics hd
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE regexp_like(hd.hd_buy_potential, '^high|medium')
  AND hd.hd_vehicle_count < (SELECT MIN(ib_lower_bound) FROM income_band)
  AND NOT EXISTS (
        SELECT 1
        FROM income_band ib2
        WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk
          AND ib2.ib_upper_bound > 150000
    )
  AND hd.hd_income_band_sk NOT IN (
        SELECT ib_income_band_sk
        FROM income_band
        WHERE ib_upper_bound = 50000
    )
UNION DISTINCT
SELECT
    CONCAT('Band_', CAST(ib.ib_income_band_sk AS VARCHAR)) AS band_label,
    hd_agg.cnt,
    hd_agg.avg_vehicle
FROM hd_agg
JOIN income_band ib
  ON hd_agg.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_upper_bound BETWEEN 60000 AND 180000
  AND hd_agg.avg_vehicle > (SELECT AVG(hd_vehicle_count) FROM household_demographics)
  AND hd_agg.hd_income_band_sk NOT IN (
        SELECT ib_income_band_sk
        FROM income_band
        WHERE ib_lower_bound < 50000
    )
