/*
Goal: Identify the ship modes with the highest total net loss for each year (2000‑2002), ranking them per year and classifying the average return amount as HIGH or LOW. The query joins all five selected tables, applies multiple filter predicates, and uses a window function for ranking.
*/
WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_ship_mode_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_hdemo_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2000 AND 2002                                   -- predicate 1
      AND sm.sm_carrier IN ('AIRBORNE', 'GERMA')                           -- predicate 2
      AND sm.sm_code = 'AIR'                                               -- predicate 3
      AND cr.cr_return_quantity BETWEEN 1 AND 5                           -- predicate 4
      AND cr.cr_return_amount > 500                                        -- predicate 5
      AND hd.hd_income_band_sk IN (1, 2, 3)                                -- predicate 6
      AND c.c_birth_country = 'United States'                             -- predicate 7
)
SELECT
    d.d_year,
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    SUM(fr.cr_net_loss) AS total_net_loss,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(fr.cr_net_loss) DESC) AS loss_rank,
    CASE WHEN AVG(fr.cr_return_amount) > 2000 THEN 'HIGH' ELSE 'LOW' END AS return_amount_category
FROM filtered_returns fr
JOIN date_dim d ON fr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm ON fr.cr_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY
    d.d_year,
    sm.sm_ship_mode_id,
    sm.sm_carrier
ORDER BY
    d.d_year,
    loss_rank
LIMIT 100
