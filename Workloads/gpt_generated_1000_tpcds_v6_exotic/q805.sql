WITH yr_dim AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
)
SELECT DISTINCT
    u.return_year,
    u.category,
    u.total_return_amount
FROM (
    SELECT
        yr.d_year AS return_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        'REFUNDED_HIGH_VEH' AS category
    FROM catalog_returns cr
    JOIN yr_dim yr ON cr.cr_returned_date_sk = yr.d_date_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count >= 3
    GROUP BY yr.d_year

    UNION ALL

    SELECT
        yr.d_year AS return_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        'RETURNING_LOW_VEH' AS category
    FROM catalog_returns cr
    JOIN yr_dim yr ON cr.cr_returned_date_sk = yr.d_date_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count <= 1
    GROUP BY yr.d_year
) u
ORDER BY u.return_year DESC, u.total_return_amount DESC
LIMIT 100
