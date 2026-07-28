WITH reason_returns AS (
    SELECT
        r.r_reason_desc AS category,
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS total_amount,
        SUM(cr.cr_return_quantity) AS total_quantity,
        CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS amount_level
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2022
    GROUP BY r.r_reason_desc, d.d_year
),
shipmode_returns AS (
    SELECT
        sm.sm_type AS category,
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS total_amount,
        SUM(cr.cr_return_quantity) AS total_quantity,
        CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS amount_level
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2022
    GROUP BY sm.sm_type, d.d_year
)
SELECT category, year, total_amount, total_quantity, amount_level
FROM reason_returns
UNION ALL
SELECT category, year, total_amount, total_quantity, amount_level
FROM shipmode_returns
ORDER BY year DESC, total_amount DESC
LIMIT 100
