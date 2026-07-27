WITH cd_filtered AS (
    SELECT cd_demo_sk,
           cd_gender,
           cd_credit_rating,
           cd_marital_status
    FROM customer_demographics
    WHERE cd_credit_rating IN ('High Risk', 'Low Risk')
)
SELECT gender,
       credit_rating,
       customer_count,
       birth_year_metric
FROM (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_credit_rating AS credit_rating,
        COUNT(c.c_customer_sk) AS customer_count,
        (SELECT MAX(c2.c_birth_year)
         FROM customer c2
         WHERE c2.c_birth_country = 'SWITZERLAND') AS birth_year_metric
    FROM customer c
    JOIN cd_filtered cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_country = 'SWITZERLAND'
      AND cd.cd_credit_rating = 'High Risk'
      AND EXISTS (
          SELECT 1
          FROM customer_demographics cd2
          WHERE cd2.cd_marital_status = cd.cd_marital_status
            AND cd2.cd_credit_rating = 'High Risk'
      )
    GROUP BY cd.cd_gender, cd.cd_credit_rating
    HAVING COUNT(c.c_customer_sk) > 5

    UNION ALL

    SELECT
        cd.cd_gender AS gender,
        cd.cd_credit_rating AS credit_rating,
        COUNT(c.c_customer_sk) AS customer_count,
        (SELECT MIN(c2.c_birth_year)
         FROM customer c2
         WHERE c2.c_birth_country = 'NICARAGUA') AS birth_year_metric
    FROM customer c
    JOIN cd_filtered cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_country = 'NICARAGUA'
      AND cd.cd_credit_rating = 'Low Risk'
      AND EXISTS (
          SELECT 1
          FROM customer_demographics cd2
          WHERE cd2.cd_marital_status = cd.cd_marital_status
            AND cd2.cd_credit_rating = 'Low Risk'
      )
    GROUP BY cd.cd_gender, cd.cd_credit_rating
    HAVING COUNT(c.c_customer_sk) > 3
) AS combined
LIMIT 100
