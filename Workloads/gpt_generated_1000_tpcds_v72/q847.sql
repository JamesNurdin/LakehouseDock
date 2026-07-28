WITH agg AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_code,
        r.r_reason_desc,
        td.t_hour,
        COUNT(*) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_amount) FILTER (WHERE cr.cr_return_quantity > 5) AS high_qty_return_amount,
        CASE WHEN SUM(cr.cr_return_amount) > 10000 THEN 'HIGH' ELSE 'LOW' END AS amount_category,
        ROW_NUMBER() OVER (PARTITION BY sm.sm_ship_mode_id ORDER BY SUM(cr.cr_return_amount) DESC) AS rn
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE
        sm.sm_code IN ('AIR', 'SEA')
        AND r.r_reason_desc LIKE '%not like%'
        AND cr.cr_return_amount > 50
        AND cr.cr_return_quantity >= 2
        AND td.t_hour BETWEEN 8 AND 20
        AND sm.sm_carrier = 'ALLIANCE'
    GROUP BY
        sm.sm_ship_mode_id,
        sm.sm_code,
        r.r_reason_desc,
        td.t_hour
)
SELECT
    ship_mode_id,
    ship_mode_code,
    reason_desc,
    hour_of_day,
    total_returns,
    total_return_amount,
    amount_category,
    rn
FROM (
    SELECT
        sm_ship_mode_id AS ship_mode_id,
        sm_code AS ship_mode_code,
        r_reason_desc AS reason_desc,
        t_hour AS hour_of_day,
        total_returns,
        total_return_amount,
        amount_category,
        rn,
        AVG(total_return_amount) OVER (PARTITION BY sm_ship_mode_id) AS avg_return_amount_per_mode
    FROM agg
) sub
WHERE avg_return_amount_per_mode > 2000
ORDER BY total_return_amount DESC
LIMIT 100
