WITH hd_ib AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ib.ib_income_band_sk
    FROM tpcds.household_demographics AS hd
    JOIN tpcds.income_band AS ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(hd.hd_buy_potential, '^[0-9]+-[0-9]+$')
      AND hd.hd_buy_potential LIKE '%-%'
)
SELECT
    hd_ib.hd_buy_potential,
    CASE
        WHEN hd_ib.hd_vehicle_count < 0 THEN 'Negative'
        WHEN hd_ib.hd_vehicle_count = 0 THEN 'None'
        WHEN hd_ib.hd_vehicle_count BETWEEN 1 AND 2 THEN 'Few'
        ELSE 'Many'
    END AS vehicle_category,
    COUNT(*) AS household_cnt,
    AVG(hd_ib.hd_vehicle_count) AS avg_vehicles,
    COUNT(*) OVER (PARTITION BY hd_ib.hd_buy_potential) AS total_households_by_potential,
    (SELECT MAX(ib_upper_bound) FROM tpcds.income_band) AS max_upper_bound_global,
    regexp_extract(hd_ib.hd_buy_potential, '(\\d+)-', 1) AS lower_range_extracted,
    concat('Band ', cast(hd_ib.ib_income_band_sk AS varchar)) AS income_band_label
FROM hd_ib
WHERE hd_ib.hd_dep_count IN (
        SELECT hd_dep_count
        FROM tpcds.household_demographics
        WHERE hd_dep_count > 3
    )
GROUP BY
    hd_ib.hd_buy_potential,
    CASE
        WHEN hd_ib.hd_vehicle_count < 0 THEN 'Negative'
        WHEN hd_ib.hd_vehicle_count = 0 THEN 'None'
        WHEN hd_ib.hd_vehicle_count BETWEEN 1 AND 2 THEN 'Few'
        ELSE 'Many'
    END,
    hd_ib.ib_income_band_sk
HAVING COUNT(*) > 5
ORDER BY household_cnt DESC, hd_ib.hd_buy_potential
