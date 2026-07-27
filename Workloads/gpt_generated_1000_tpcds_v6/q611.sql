WITH joined AS (
    SELECT
        cc.cc_manager,
        cc.cc_name,
        w.w_warehouse_name,
        sm.sm_type,
        r.r_reason_desc,
        td.t_hour,
        cp.cp_catalog_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cc.cc_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
      AND cp.cp_catalog_number IN (4, 7, 16)
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc LIKE '%time%'
      AND td.t_hour BETWEEN 9 AND 17
),
agg AS (
    SELECT
        cc_manager AS manager,
        w_warehouse_name AS warehouse,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_net_loss) AS total_net_loss
    FROM joined
    GROUP BY cc_manager, w_warehouse_name
)
SELECT
    manager,
    warehouse,
    total_return_amount,
    total_return_quantity,
    total_net_loss,
    RANK() OVER (PARTITION BY manager ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY manager, loss_rank
LIMIT 100
