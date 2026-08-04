WITH filtered AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_current_hdemo_sk,
        c.c_first_sales_date_sk,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        cd.cd_credit_rating
    FROM
        tpcds.customer AS c
        INNER JOIN tpcds.customer_demographics AS cd
            ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_year BETWEEN 1930 AND 1980                     -- predicate 1
        AND cd.cd_dep_count >= 2                                 -- predicate 2
        AND cd.cd_dep_college_count <= 5                         -- predicate 3
        AND c.c_current_hdemo_sk IN (6807, 6577, 134)            -- predicate 4
        AND c.c_first_sales_date_sk > 2451500                    -- predicate 5
        AND cd.cd_gender IN ('M', 'F')                           -- predicate 6
), ranked AS (
    SELECT
        f.c_customer_id,
        f.c_first_name,
        f.c_last_name,
        f.c_birth_year,
        f.cd_gender,
        f.cd_marital_status,
        f.cd_dep_count,
        f.cd_dep_college_count,
        ROW_NUMBER() OVER (PARTITION BY f.cd_gender ORDER BY f.c_birth_year DESC) AS gender_birth_rank,
        RANK() OVER (ORDER BY f.cd_dep_count DESC) AS dep_count_rank
    FROM
        filtered AS f
)
SELECT
    r.c_customer_id,
    r.c_first_name,
    r.c_last_name,
    r.c_birth_year,
    r.cd_gender,
    r.cd_marital_status,
    r.cd_dep_count,
    r.cd_dep_college_count,
    r.gender_birth_rank,
    r.dep_count_rank
FROM
    ranked AS r
ORDER BY
    r.gender_birth_rank,
    r.c_customer_id
LIMIT 100
