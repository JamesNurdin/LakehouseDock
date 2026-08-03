WITH full_joined AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_employed_count
    FROM tpcds.customer c
    FULL OUTER JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

country_dim AS (
    SELECT DISTINCT c_birth_country
    FROM tpcds.customer
    WHERE c_birth_country IS NOT NULL
),

set_a AS (
    SELECT
        cdim.c_birth_country,
        fj.c_customer_sk,
        fj.c_first_name,
        fj.c_last_name,
        fj.cd_gender,
        fj.cd_marital_status,
        (
            SELECT COUNT(*)
            FROM tpcds.customer
            WHERE c_birth_country = cdim.c_birth_country
        ) AS country_customer_cnt
    FROM country_dim cdim
    CROSS JOIN (
        SELECT *
        FROM full_joined fj
        WHERE fj.c_birth_country = 'JAPAN'
          AND fj.cd_marital_status = 'M'
          AND NOT EXISTS (
              SELECT 1
              FROM tpcds.customer_demographics cd2
              WHERE cd2.cd_demo_sk = fj.c_current_cdemo_sk
                AND cd2.cd_gender = 'F'
          )
    ) fj
),

set_b AS (
    SELECT
        cdim.c_birth_country,
        fj.c_customer_sk,
        fj.c_first_name,
        fj.c_last_name,
        fj.cd_gender,
        fj.cd_marital_status,
        (
            SELECT COUNT(*)
            FROM tpcds.customer
            WHERE c_birth_country = cdim.c_birth_country
        ) AS country_customer_cnt
    FROM country_dim cdim
    CROSS JOIN (
        SELECT *
        FROM full_joined fj
        WHERE fj.c_birth_country = 'AZERBAIJAN'
          AND fj.cd_marital_status = 'S'
          AND NOT EXISTS (
              SELECT 1
              FROM tpcds.customer_demographics cd2
              WHERE cd2.cd_demo_sk = fj.c_current_cdemo_sk
                AND cd2.cd_gender = 'M'
          )
    ) fj
)
SELECT *
FROM set_a
UNION ALL
SELECT *
FROM set_b
ORDER BY c_birth_country, c_customer_sk
LIMIT 100
