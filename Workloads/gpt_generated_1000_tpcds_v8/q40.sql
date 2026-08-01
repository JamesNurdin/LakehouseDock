WITH rc_agg AS (
    SELECT
        cr_reason_sk,
        cr_ship_mode_sk,
        SUM(cr_return_amount)        AS total_return_amount,
        AVG(cr_return_tax)           AS avg_return_tax,
        COUNT(*)                     AS return_cnt,
        MIN(cr_return_amount)        AS min_return_amount,
        MAX(cr_return_amount)        AS max_return_amount
    FROM catalog_returns
    WHERE cr_return_amount      > 50.00                     -- high value returns
      AND cr_return_tax        BETWEEN 10 AND 100           -- moderate tax range
      AND cr_warehouse_sk      IN (1, 2, 14)                -- selected warehouses
      AND cr_returning_cdemo_sk > 1000000                  -- adult customers
      AND cr_return_quantity  >= 1                        -- at least one item returned
    GROUP BY cr_reason_sk, cr_ship_mode_sk
)
SELECT
    ship_mode.sm_ship_mode_id,
    ship_mode.sm_type,
    reason.r_reason_desc,
    rc_agg.total_return_amount,
    rc_agg.avg_return_tax,
    rc_agg.return_cnt,
    rc_agg.min_return_amount,
    rc_agg.max_return_amount,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr_sub
        WHERE cr_sub.cr_ship_mode_sk = ship_mode.sm_ship_mode_sk
    ) AS total_returns_for_ship_mode
FROM rc_agg
RIGHT OUTER JOIN ship_mode
    ON rc_agg.cr_ship_mode_sk = ship_mode.sm_ship_mode_sk
LEFT JOIN reason
    ON rc_agg.cr_reason_sk = reason.r_reason_sk
WHERE EXISTS (
        SELECT 1
        FROM reason r_semi
        WHERE r_semi.r_reason_sk = rc_agg.cr_reason_sk
          AND r_semi.r_reason_desc LIKE '%price%'
    )
  AND ship_mode.sm_code = 'AIR'                          -- keep only air shipments
  AND reason.r_reason_id = 'AAAAAAAALAAAAAAA'           -- specific reason id
  AND ship_mode.sm_contract IS NOT NULL                  -- contract must exist
  AND rc_agg.total_return_amount > 500.00               -- meaningful aggregate
  AND rc_agg.return_cnt >= 5                            -- enough occurrences
ORDER BY rc_agg.total_return_amount DESC
LIMIT 100
