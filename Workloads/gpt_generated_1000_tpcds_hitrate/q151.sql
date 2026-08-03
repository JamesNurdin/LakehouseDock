WITH joined AS (
    SELECT
        cr.cr_ship_mode_sk,
        cr.cr_return_amount,
        cr.cr_store_credit,
        sm.sm_ship_mode_id,
        sm.sm_code,
        sm.sm_contract,
        td.t_shift,
        td.t_minute
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE sm.sm_code IN ('AIR', 'SEA')
      AND sm.sm_contract LIKE 'yVfotg7%'
      AND td.t_shift = 'first'
      AND td.t_minute BETWEEN 5 AND 15
      AND cr.cr_store_credit > 100
),
agg1 AS (
    SELECT
        sm_ship_mode_id,
        sm_code,
        t_shift,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_store_credit) AS avg_store_credit,
        COUNT(*) AS cnt,
        CASE WHEN SUM(cr_return_amount) > 500 THEN 'high' ELSE 'low' END AS return_level
    FROM joined
    GROUP BY sm_ship_mode_id, sm_code, t_shift
),
ranked AS (
    SELECT
        sm_ship_mode_id,
        sm_code,
        t_shift,
        total_return_amount,
        avg_store_credit,
        cnt,
        return_level,
        ROW_NUMBER() OVER (PARTITION BY sm_ship_mode_id ORDER BY total_return_amount DESC) AS rn
    FROM agg1
)
SELECT
    sm_ship_mode_id,
    sm_code,
    t_shift,
    total_return_amount,
    avg_store_credit,
    cnt,
    return_level
FROM ranked
WHERE rn <= 3
ORDER BY sm_ship_mode_id, rn
LIMIT 100
