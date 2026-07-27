WITH max_birth_year AS (
    SELECT max(c_birth_year) AS max_year FROM tpcds.customer
),
sub1 AS (
    SELECT
        hd.hd_income_band_sk,
        CASE
            WHEN c.c_birth_year < 1960 THEN 'Senior'
            ELSE 'Adult'
        END AS age_group,
        COUNT(*) AS customer_cnt,
        (SELECT max_year FROM max_birth_year) AS overall_max_birth_year
    FROM tpcds.customer c
    JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_year <= 1970
      AND hd.hd_dep_count >= 2
    GROUP BY hd.hd_income_band_sk,
        CASE
            WHEN c.c_birth_year < 1960 THEN 'Senior'
            ELSE 'Adult'
        END
),
sub2 AS (
    SELECT
        hd.hd_income_band_sk,
        CASE
            WHEN c.c_birth_year BETWEEN 1971 AND 1990 THEN 'Middle'
            ELSE 'Young'
        END AS age_group,
        COUNT(*) AS customer_cnt,
        (SELECT max_year FROM max_birth_year) AS overall_max_birth_year
    FROM tpcds.customer c
    JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_year > 1970
      AND hd.hd_vehicle_count > 0
    GROUP BY hd.hd_income_band_sk,
        CASE
            WHEN c.c_birth_year BETWEEN 1971 AND 1990 THEN 'Middle'
            ELSE 'Young'
        END
)
SELECT *
FROM sub1
UNION ALL
SELECT *
FROM sub2
ORDER BY hd_income_band_sk, age_group, customer_cnt DESC
LIMIT 100
