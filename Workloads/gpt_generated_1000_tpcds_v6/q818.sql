WITH filtered_college AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_credit_rating,
        c.c_birth_year
    FROM customer c
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_education_status = 'College'
      AND cd.cd_dep_employed_count >= 2
      AND EXISTS (
          SELECT 1
          FROM customer_demographics cd2
          WHERE cd2.cd_demo_sk = c.c_current_cdemo_sk
            AND cd2.cd_credit_rating = 'A'
      )
)
SELECT DISTINCT
    u.c_customer_id,
    u.c_first_name,
    u.c_last_name,
    u.cd_gender,
    u.cd_education_status,
    u.cd_credit_rating
FROM (
    SELECT
        c_customer_id,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_education_status,
        cd_credit_rating
    FROM filtered_college
    WHERE c_birth_year BETWEEN 1950 AND 1990

    UNION

    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
      AND c.c_birth_year BETWEEN 1960 AND 1970
      AND cd.cd_dep_employed_count = 0
) u
LIMIT 100
