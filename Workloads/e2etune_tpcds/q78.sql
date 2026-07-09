WITH aggregated AS (
    SELECT
        w.w_state,
        sm.sm_type,
        r.r_reason_desc,
        COUNT(*) AS num_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_tax) AS total_tax,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(cr.cr_return_ship_cost) AS total_ship_cost,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
      AND cr.cr_return_amount > 0
    GROUP BY w.w_state, sm.sm_type, r.r_reason_desc
)
SELECT
    a.w_state,
    a.sm_type,
    a.r_reason_desc,
    a.num_returns,
    a.total_return_amount,
    a.total_tax,
    a.avg_return_amount,
    a.total_ship_cost,
    a.total_net_loss,
    RANK() OVER (PARTITION BY a.w_state ORDER BY a.total_return_amount DESC) AS state_rank
FROM aggregated a
WHERE a.num_returns >= 10
ORDER BY a.w_state, state_rank
LIMIT 50
