WITH
    filtered_hd AS (
        SELECT
            hd.hd_demo_sk,
            hd.hd_income_band_sk,
            hd.hd_buy_potential,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            hd.hd_vehicle_count,
            hd.hd_dep_count,
            CONCAT(hd.hd_buy_potential, '_', CAST(ib.ib_lower_bound AS VARCHAR)) AS potential_range,
            SUBSTRING(hd.hd_buy_potential FROM 1 FOR 3) AS buy_prefix,
            CASE
                WHEN REGEXP_LIKE(hd.hd_buy_potential, '^high') THEN 'High'
                WHEN REGEXP_LIKE(hd.hd_buy_potential, '^low') THEN 'Low'
                ELSE 'Medium'
            END AS potential_category
        FROM household_demographics hd
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE hd.hd_buy_potential LIKE '%potential%'
          AND REGEXP_LIKE(hd.hd_buy_potential, '[A-Z][a-z]+')
    ),
    band_stats AS (
        SELECT
            ib.ib_income_band_sk,
            COUNT(DISTINCT hd.hd_demo_sk) AS hh_count,
            AVG(hd.hd_vehicle_count) AS avg_vehicles,
            SUM(hd.hd_dep_count) AS total_dependents,
            ROW_NUMBER() OVER (
                PARTITION BY ib.ib_income_band_sk
                ORDER BY AVG(hd.hd_vehicle_count) DESC
            ) AS rn
        FROM household_demographics hd
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY ib.ib_income_band_sk
        HAVING COUNT(DISTINCT hd.hd_demo_sk) > 1
    ),
    set_a AS (
        SELECT hd_demo_sk
        FROM household_demographics
        WHERE hd_buy_potential LIKE 'A%'
          AND hd_vehicle_count >= 2
    ),
    set_b AS (
        SELECT hd_demo_sk
        FROM household_demographics
        WHERE hd_buy_potential LIKE '%Z'
          AND hd_dep_count <= 4
    ),
    union_sets AS (
        SELECT hd_demo_sk FROM set_a
        UNION
        SELECT hd_demo_sk FROM set_b
    ),
    intersect_a AS (
        SELECT hd.hd_demo_sk
        FROM household_demographics hd
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE REGEXP_EXTRACT(hd.hd_buy_potential, '(\\d+)') IS NOT NULL
          AND ib.ib_upper_bound > 100000
    ),
    intersect_b AS (
        SELECT hd.hd_demo_sk
        FROM household_demographics hd
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE hd.hd_buy_potential LIKE '%budget%'
          AND ib.ib_lower_bound < 150000
    ),
    intersect_keys AS (
        SELECT hd_demo_sk FROM intersect_a
        INTERSECT
        SELECT hd_demo_sk FROM intersect_b
    )
SELECT DISTINCT
    fh.hd_demo_sk,
    fh.potential_category,
    fh.potential_range,
    fh.buy_prefix,
    bs.hh_count,
    bs.avg_vehicles,
    bs.total_dependents,
    bs.rn
FROM filtered_hd fh
JOIN band_stats bs
    ON fh.hd_income_band_sk = bs.ib_income_band_sk
WHERE fh.hd_demo_sk IN (SELECT hd_demo_sk FROM intersect_keys)
  AND fh.hd_demo_sk IN (SELECT hd_demo_sk FROM union_sets)
ORDER BY bs.hh_count DESC, fh.hd_demo_sk
