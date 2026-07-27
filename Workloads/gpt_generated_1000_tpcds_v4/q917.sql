WITH aggregated_returns AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_code,
        sm.sm_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_amount > 0
    GROUP BY sm.sm_ship_mode_id, sm.sm_code, sm.sm_type
)
SELECT
    sm_ship_mode_id,
    sm_code,
    sm_type,
    total_return_amount,
    return_cnt
FROM aggregated_returns
WHERE sm_code = 'AIR'
UNION ALL
SELECT
    sm_ship_mode_id,
    sm_code,
    sm_type,
    total_return_amount,
    return_cnt
FROM aggregated_returns
WHERE sm_code = 'SEA'
ORDER BY total_return_amount DESC
LIMIT 100
