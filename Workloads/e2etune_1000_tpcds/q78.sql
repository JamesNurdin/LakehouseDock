WITH warehouse_reason_stats AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_ship_mode_sk,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_ship_cost) AS total_ship_cost,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450300
      AND cr.cr_return_amount > 0
    GROUP BY cr.cr_warehouse_sk, cr.cr_reason_sk, cr.cr_ship_mode_sk
)
SELECT
    w.w_warehouse_name,
    r.r_reason_desc,
    sm.sm_carrier,
    ws.total_net_loss,
    ws.total_return_amount,
    ws.total_ship_cost,
    ws.return_cnt,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY ws.total_net_loss DESC) AS loss_rank
FROM warehouse_reason_stats ws
JOIN warehouse w
    ON ws.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
    ON ws.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
    ON ws.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ws.total_net_loss > 1000
ORDER BY ws.total_net_loss DESC
LIMIT 50
