WITH high_price_items AS (
    SELECT i_item_sk, i_current_price
    FROM item
    WHERE i_current_price > 100.00
),
unioned_returns AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode,
        'AIR' AS mode_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS return_orders
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN high_price_items hi
        ON cr.cr_item_sk = hi.i_item_sk
    WHERE sm.sm_code = 'AIR'
      AND cr.cr_returned_date_sk BETWEEN 2450867 AND 2450980
    GROUP BY sm.sm_ship_mode_id

    UNION ALL

    SELECT
        sm.sm_ship_mode_id AS ship_mode,
        'NON_AIR' AS mode_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS return_orders
    FROM catalog_returns cr
    LEFT JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code <> 'AIR'
      AND NOT EXISTS (
            SELECT 1
            FROM catalog_sales cs2
            WHERE cs2.cs_order_number = cr.cr_order_number
        )
      AND cr.cr_returned_date_sk BETWEEN 2450867 AND 2450980
    GROUP BY sm.sm_ship_mode_id
)
SELECT
    ship_mode,
    mode_category,
    total_return_amount,
    return_orders,
    (SELECT AVG(cr_return_amount) FROM catalog_returns) AS overall_avg_return_amount
FROM unioned_returns
ORDER BY total_return_amount DESC
