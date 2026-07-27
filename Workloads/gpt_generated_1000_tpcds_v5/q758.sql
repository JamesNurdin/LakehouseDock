WITH warehouse_returns AS (
    SELECT
        'Warehouse' AS category,
        w.w_warehouse_name AS identifier,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        CASE WHEN AVG(cr.cr_return_tax) > 100 THEN 'High' ELSE 'Low' END AS tax_level
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States'
      AND w.w_warehouse_sq_ft > 500000
      AND cr.cr_return_tax > 50
    GROUP BY w.w_warehouse_name
    HAVING SUM(cr.cr_return_amount) > 1000
),
shipmode_returns AS (
    SELECT
        'ShipMode' AS category,
        sm.sm_ship_mode_id AS identifier,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        CASE WHEN AVG(cr.cr_return_tax) > 40 THEN 'High' ELSE 'Low' END AS tax_level
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier = 'AIRBORNE'
      AND cr.cr_return_tax BETWEEN 0 AND 50
    GROUP BY sm.sm_ship_mode_id
    HAVING COUNT(*) >= 10
)
SELECT *
FROM warehouse_returns
UNION ALL
SELECT *
FROM shipmode_returns
ORDER BY total_return_amount DESC
LIMIT 100
