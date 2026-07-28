WITH base AS (
    SELECT
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        d.d_year,
        i.i_category,
        i.i_manufact,
        sm.sm_carrier
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND i.i_category_id IN (1, 5, 8)
      AND i.i_manufact_id = 338
      AND sm.sm_carrier = 'GREAT EASTERN'
      AND d.d_current_month = 'Y'
      AND cr.cr_return_amount > 10
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_order_number = cr.cr_order_number
            AND cr2.cr_net_loss = 0
      )
)
SELECT
    COALESCE(i_category, 'ALL') AS category,
    COALESCE(i_manufact, 'ALL') AS manufacturer,
    COALESCE(CAST(d_year AS VARCHAR), 'ALL') AS year,
    CASE WHEN SUM(cr_net_loss) > 1000 THEN 'HIGH' ELSE 'LOW' END AS loss_level,
    COUNT(*) AS return_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_quantity) AS avg_quantity
FROM base
GROUP BY GROUPING SETS (
    (i_category, i_manufact, d_year),
    (i_category, i_manufact),
    (i_category),
    ()
)
ORDER BY category, manufacturer, year, loss_level DESC
LIMIT 100
