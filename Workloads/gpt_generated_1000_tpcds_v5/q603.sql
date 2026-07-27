WITH regular_returns AS (
    SELECT sm.sm_ship_mode_id,
           sm.sm_type,
           SUM(cr.cr_return_amount) AS total_return_amount,
           AVG(cr.cr_return_ship_cost) AS avg_ship_cost
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'REGULAR'
      AND sm.sm_contract LIKE 'A%'
    GROUP BY sm.sm_ship_mode_id, sm.sm_type
),
express_returns AS (
    SELECT sm.sm_ship_mode_id,
           sm.sm_type,
           SUM(cr.cr_return_amount) AS total_return_amount,
           AVG(cr.cr_return_ship_cost) AS avg_ship_cost
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'EXPRESS'
      AND sm.sm_contract NOT LIKE 'A%'
    GROUP BY sm.sm_ship_mode_id, sm.sm_type
)
SELECT
    regular_returns.sm_ship_mode_id,
    regular_returns.sm_type,
    regular_returns.total_return_amount,
    regular_returns.avg_ship_cost
FROM regular_returns
UNION ALL
SELECT
    express_returns.sm_ship_mode_id,
    express_returns.sm_type,
    express_returns.total_return_amount,
    express_returns.avg_ship_cost
FROM express_returns
LIMIT 100
