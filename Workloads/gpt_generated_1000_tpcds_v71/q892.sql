WITH base AS (
    SELECT
        cr.cr_ship_mode_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_order_number
    FROM catalog_returns AS cr
    WHERE cr.cr_return_amount > 100                               -- predicate 1
      AND cr.cr_return_quantity BETWEEN 1 AND 5                    -- predicate 2
      AND cr.cr_order_number IN (9, 11, 21)                        -- predicate 3
)
SELECT
    sm.sm_carrier,
    sm.sm_code,
    COUNT(*) AS returns_cnt,
    SUM(b.cr_return_amount) AS total_return_amount,
    AVG(b.cr_return_amount) AS avg_return_amount,
    MIN(b.cr_return_amount) AS min_return_amount,
    MAX(b.cr_return_amount) AS max_return_amount
FROM base AS b
JOIN ship_mode AS sm
    ON b.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_carrier IN ('UPS', 'DHL')                               -- predicate 4
  AND sm.sm_code = 'AIR'                                             -- predicate 5
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns AS cr_ex
        WHERE cr_ex.cr_order_number = b.cr_order_number
          AND cr_ex.cr_return_amount = 0
    )
GROUP BY sm.sm_carrier, sm.sm_code
ORDER BY total_return_amount DESC
