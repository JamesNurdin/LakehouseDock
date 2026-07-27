WITH per_mode_shift AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        td.t_sub_shift,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE sm.sm_code IN ('AIR', 'SEA')
      AND td.t_hour BETWEEN 6 AND 19
      AND cr.cr_return_quantity > 1
    GROUP BY sm.sm_ship_mode_id, td.t_sub_shift
)
SELECT
    ship_mode_id,
    AVG(total_net_loss) AS avg_net_loss_per_shift,
    SUM(return_cnt) AS total_returns
FROM per_mode_shift
GROUP BY ship_mode_id
HAVING AVG(total_net_loss) > 1000
ORDER BY avg_net_loss_per_shift DESC
LIMIT 100
