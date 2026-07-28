WITH hd AS (
    SELECT
        hd_demo_sk,
        hd_income_band_sk,
        hd_dep_count,
        hd_vehicle_count,
        hd_buy_potential,
        CASE
            WHEN regexp_like(hd_buy_potential, '^\\d+-\\d+$') THEN cast(regexp_extract(hd_buy_potential, '(\\d+)-(\\d+)', 1) AS integer)
            WHEN regexp_like(hd_buy_potential, '^>\\d+$') THEN cast(regexp_extract(hd_buy_potential, '>(\\d+)', 1) AS integer)
            ELSE NULL
        END AS buy_low
    FROM household_demographics
    WHERE hd_buy_potential IS NOT NULL
)
SELECT
    ib.ib_income_band_sk,
    concat('Income ', cast(ib.ib_lower_bound AS varchar), '-', cast(ib.ib_upper_bound AS varchar)) AS income_range,
    count(DISTINCT hd.hd_demo_sk) AS household_count,
    avg(hd.hd_vehicle_count) AS avg_vehicle_count,
    avg(hd.hd_dep_count) AS avg_dependents,
    avg(hd.buy_low) FILTER (WHERE hd.buy_low IS NOT NULL) AS avg_buy_low
FROM hd
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    hd.hd_buy_potential LIKE '%-%'                           -- contains a range
    AND regexp_like(hd.hd_buy_potential, '^\\d+-\\d+$')   -- exact range format
    AND cast(regexp_extract(hd.hd_buy_potential, '(\\d+)-(\\d+)', 1) AS integer) >= 1000
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY
    household_count DESC
LIMIT 100
