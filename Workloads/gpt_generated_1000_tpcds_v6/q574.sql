WITH filtered_hd AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        regexp_extract(hd.hd_buy_potential, '(\\d+)', 1) AS potential_score,
        concat('Potential-', hd.hd_buy_potential) AS buy_potential_label
    FROM tpcds.household_demographics hd
    WHERE regexp_like(hd.hd_buy_potential, '^M[0-9]{2,}$')
      AND hd.hd_buy_potential LIKE '%5%'
      AND EXISTS (
          SELECT 1
          FROM tpcds.household_demographics hd2
          WHERE hd2.hd_income_band_sk = hd.hd_income_band_sk
            AND hd2.hd_dep_count > 5
      )
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(fhd.hd_demo_sk) AS household_cnt,
    AVG(fhd.hd_vehicle_count) AS avg_vehicle_cnt,
    AVG(CAST(fhd.potential_score AS double)) AS avg_potential_score
FROM filtered_hd fhd
JOIN tpcds.income_band ib
    ON fhd.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
HAVING COUNT(fhd.hd_demo_sk) >= 5
ORDER BY avg_vehicle_cnt DESC
LIMIT 100
