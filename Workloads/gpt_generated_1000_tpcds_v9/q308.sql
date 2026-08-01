WITH aggregated AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_quantity,
        COUNT(*) AS return_count,
        GROUPING(sm.sm_carrier) AS g_carrier,
        GROUPING(sm.sm_ship_mode_id) AS g_ship_mode_id
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_amount > 100
    GROUP BY GROUPING SETS (
        (sm.sm_ship_mode_sk, sm.sm_ship_mode_id, sm.sm_carrier),
        (sm.sm_ship_mode_sk, sm.sm_ship_mode_id),
        (sm.sm_ship_mode_sk)
    )
    HAVING SUM(cr.cr_return_amount) > 500
)
SELECT
    a.sm_ship_mode_id,
    a.sm_carrier,
    a.total_return_amount,
    a.total_quantity,
    a.return_count,
    ROW_NUMBER() OVER (PARTITION BY a.sm_ship_mode_id ORDER BY a.total_return_amount DESC) AS rn,
    (
        SELECT MAX(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_ship_mode_sk = a.sm_ship_mode_sk
    ) AS max_return_amount
FROM aggregated a
WHERE a.g_carrier = 0
  AND a.sm_ship_mode_id IN (
        SELECT DISTINCT sm_ship_mode_id
        FROM ship_mode
        WHERE sm_carrier = 'UPS'
    )
UNION
SELECT
    a.sm_ship_mode_id,
    a.sm_carrier,
    a.total_return_amount,
    a.total_quantity,
    a.return_count,
    ROW_NUMBER() OVER (PARTITION BY a.sm_ship_mode_id ORDER BY a.total_return_amount DESC) AS rn,
    (
        SELECT MAX(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_ship_mode_sk = a.sm_ship_mode_sk
    ) AS max_return_amount
FROM aggregated a
WHERE a.g_carrier = 1
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        WHERE cr3.cr_ship_mode_sk = a.sm_ship_mode_sk
          AND cr3.cr_return_tax > 5
    )
LIMIT 100
