WITH returns_by_warehouse_reason_shift AS (
    SELECT
        w.w_warehouse_name,
        r.r_reason_desc,
        t.t_shift,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        SUM(cr.cr_return_quantity) AS total_quantity,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2000
    GROUP BY w.w_warehouse_name, r.r_reason_desc, t.t_shift
)
SELECT
    w_warehouse_name,
    r_reason_desc,
    t_shift,
    total_net_loss,
    return_count,
    total_quantity,
    avg_return_amount,
    avg_vehicle_count
FROM returns_by_warehouse_reason_shift
ORDER BY total_net_loss DESC
LIMIT 100
