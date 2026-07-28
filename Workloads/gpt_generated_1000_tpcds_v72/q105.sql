WITH top_returns AS (
    SELECT
        cr.cr_warehouse_sk AS warehouse_sk,
        sm.sm_carrier AS carrier,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier IN ('UPS', 'DIAMOND')
      AND cr.cr_return_ship_cost > 100
    GROUP BY cr.cr_warehouse_sk, sm.sm_carrier
    HAVING SUM(cr.cr_return_amount) > 500
)
SELECT
    tr.warehouse_sk,
    tr.carrier,
    tr.total_return_amount,
    tr.return_cnt
FROM top_returns tr
WHERE tr.total_return_amount > (
    SELECT AVG(cr2.cr_return_amount)
    FROM catalog_returns cr2
    WHERE cr2.cr_warehouse_sk = tr.warehouse_sk
)
UNION ALL
SELECT
    cr.cr_warehouse_sk AS warehouse_sk,
    sm.sm_carrier AS carrier,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt
FROM catalog_returns cr
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_contract <> 'HVDFCcQ'
  AND NOT EXISTS (
        SELECT 1
        FROM ship_mode sm2
        WHERE sm2.sm_ship_mode_sk = cr.cr_ship_mode_sk
          AND sm2.sm_contract = 'HVDFCcQ'
      )
GROUP BY cr.cr_warehouse_sk, sm.sm_carrier
HAVING SUM(cr.cr_return_amount) > 300
ORDER BY total_return_amount DESC
LIMIT 100
