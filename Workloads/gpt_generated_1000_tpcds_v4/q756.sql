WITH filtered AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        hd.hd_buy_potential
    FROM tpcds.household_demographics hd
    WHERE hd.hd_buy_potential LIKE '%high%'
      AND regexp_like(hd.hd_buy_potential, '^M[0-9]+$')
)
SELECT
    CONCAT(CAST(ib.ib_lower_bound AS VARCHAR), '-', CAST(ib.ib_upper_bound AS VARCHAR)) AS income_range,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT f.hd_demo_sk) AS distinct_households,
    AVG(f.hd_vehicle_count) AS avg_vehicle_count,
    REGEXP_EXTRACT(MIN(f.hd_buy_potential), '[0-9]+') AS sample_numeric_part
FROM filtered f
JOIN tpcds.income_band ib
  ON f.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY
    CONCAT(CAST(ib.ib_lower_bound AS VARCHAR), '-', CAST(ib.ib_upper_bound AS VARCHAR)),
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY
    distinct_households DESC,
    income_range
