WITH
    base_refunded AS (
        SELECT
            d.d_year,
            cd.cd_gender,
            t.t_meal_time,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        WHERE d.d_year = 2001
          AND t.t_meal_time = 'lunch'
          AND cd.cd_gender = 'M'
          AND cr.cr_return_amount > 20
          AND NOT EXISTS (
                SELECT 1
                FROM catalog_returns cr2
                WHERE cr2.cr_order_number = cr.cr_order_number
                  AND cr2.cr_return_amount = 0
          )
        GROUP BY GROUPING SETS (
            (d.d_year, cd.cd_gender, t.t_meal_time),
            (d.d_year, cd.cd_gender),
            (d.d_year),
            ()
        )
    ),
    base_returning AS (
        SELECT
            d.d_year,
            cd.cd_gender,
            t.t_meal_time,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
        WHERE d.d_year = 2002
          AND t.t_meal_time = 'dinner'
          AND cd.cd_gender = 'F'
          AND cr.cr_return_amount > 30
          AND NOT EXISTS (
                SELECT 1
                FROM catalog_returns cr2
                WHERE cr2.cr_order_number = cr.cr_order_number
                  AND cr2.cr_return_amount = 0
          )
        GROUP BY GROUPING SETS (
            (d.d_year, cd.cd_gender, t.t_meal_time),
            (d.d_year, cd.cd_gender),
            (d.d_year),
            ()
        )
    ),
    unioned AS (
        SELECT * FROM base_refunded
        UNION ALL
        SELECT * FROM base_returning
    )
SELECT
    d_year,
    cd_gender,
    t_meal_time,
    total_return_amount,
    return_cnt,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS rank_within_year
FROM unioned
ORDER BY d_year NULLS LAST, total_return_amount DESC
LIMIT 100
