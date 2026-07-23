WITH warehouse_stats AS (
    SELECT
        cr_warehouse_sk,
        AVG(cr_return_quantity) AS avg_qty,
        MAX(cr_return_amount) AS max_return_amount
    FROM catalog_returns
    GROUP BY cr_warehouse_sk
)
SELECT
    sm.sm_carrier,
    sm.sm_type,
    cr.cr_warehouse_sk,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amt_inc_tax) AS avg_return_inc_tax,
    COUNT(*) AS return_count,
    MIN(cr.cr_fee) AS min_fee,
    MAX(cr.cr_return_quantity) AS max_quantity,
    (SELECT COUNT(*) FROM catalog_returns cr_sub WHERE cr_sub.cr_warehouse_sk = cr.cr_warehouse_sk) AS total_returns_per_warehouse,
    ws.avg_qty,
    ws.max_return_amount
FROM catalog_returns cr
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse_stats ws
    ON cr.cr_warehouse_sk = ws.cr_warehouse_sk
WHERE cr.cr_return_amt_inc_tax > 1000
  AND cr.cr_warehouse_sk IN (3, 12, 15)
  AND sm.sm_carrier = 'PRIVATECARRIER'
  AND sm.sm_contract = 'qENFQ'
  AND cr.cr_fee < 50
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cr.cr_order_number
          AND cr2.cr_return_amount > 5000
    )
GROUP BY sm.sm_carrier, sm.sm_type, cr.cr_warehouse_sk, ws.avg_qty, ws.max_return_amount
ORDER BY total_return_amount DESC
LIMIT 100
