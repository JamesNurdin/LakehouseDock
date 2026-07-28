WITH male_stats AS (
    SELECT
        c.c_birth_year AS birth_year,
        cd.cd_gender   AS gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_cnt
    FROM
        tpcds.customer c
        JOIN tpcds.customer_demographics cd
            ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_gender = 'M'
        AND cd.cd_purchase_estimate >= 5000
    GROUP BY
        c.c_birth_year,
        cd.cd_gender
),
female_stats AS (
    SELECT
        c.c_birth_year AS birth_year,
        cd.cd_gender   AS gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_cnt
    FROM
        tpcds.customer c
        JOIN tpcds.customer_demographics cd
            ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_gender = 'F'
        AND cd.cd_purchase_estimate < 2000
    GROUP BY
        c.c_birth_year,
        cd.cd_gender
)
SELECT
    birth_year,
    gender,
    customer_cnt
FROM male_stats
UNION ALL
SELECT
    birth_year,
    gender,
    customer_cnt
FROM female_stats
ORDER BY birth_year, gender
