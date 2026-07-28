WITH filtered_hd AS (
    SELECT
        hd_demo_sk,
        hd_income_band_sk,
        hd_buy_potential,
        hd_vehicle_count,
        hd_dep_count,
        CASE
            WHEN regexp_like(hd_buy_potential, '^>') THEN CAST(regexp_extract(hd_buy_potential, '\\>(\\d+)', 1) AS integer)
            WHEN regexp_like(hd_buy_potential, '^(\\d+)-') THEN CAST(regexp_extract(hd_buy_potential, '^(\\d+)-', 1) AS integer)
            ELSE NULL
        END AS buy_lower_bound
    FROM tpcds.household_demographics
    WHERE hd_buy_potential LIKE '5%'               -- values starting with 5 (e.g., '5001-10000')
      AND hd_vehicle_count >= 0
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(fhd.hd_demo_sk)                     AS household_cnt,
    AVG(fhd.hd_vehicle_count)                AS avg_vehicle_cnt,
    SUM(fhd.hd_dep_count)                    AS total_dep_cnt,
    concat('Band ', CAST(ib.ib_income_band_sk AS varchar), ': ', COALESCE(MIN(fhd.hd_buy_potential), 'N/A')) AS band_buy_potential_label
FROM filtered_hd fhd
JOIN tpcds.income_band ib
    ON fhd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_lower_bound >= 100000
  AND regexp_like(CAST(ib.ib_upper_bound AS varchar), '^1[0-9]{5}$')   -- upper bound is a six‑digit number starting with 1
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
HAVING COUNT(fhd.hd_demo_sk) > 5
ORDER BY household_cnt DESC
LIMIT 100
