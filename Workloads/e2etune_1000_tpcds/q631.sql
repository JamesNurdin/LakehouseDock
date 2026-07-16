WITH inv_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory
    GROUP BY inv_warehouse_sk
),
return_agg AS (
    SELECT
        w.w_city AS warehouse_city,
        r.r_reason_desc AS return_reason,
        td.t_shift AS shift,
        COUNT(*) AS num_returns,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        inv_agg.total_inventory_qty
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inv_agg ON w.w_warehouse_sk = inv_agg.inv_warehouse_sk
    LEFT JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    LEFT JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450935 AND 2451132
      AND cr.cr_net_loss > 100
      AND sm.sm_type = 'GROUND'
      AND w.w_state = 'CA'
      AND cd_ret.cd_gender = 'M'
      AND hd_ret.hd_buy_potential = 'HIGH'
    GROUP BY w.w_city, r.r_reason_desc, td.t_shift, inv_agg.total_inventory_qty
    HAVING COUNT(*) > 5
)
SELECT
    warehouse_city,
    return_reason,
    shift,
    num_returns,
    total_net_loss,
    avg_return_amount,
    total_return_quantity,
    total_inventory_qty,
    (total_return_quantity * 1.0 / NULLIF(total_inventory_qty, 0)) AS return_to_inventory_ratio,
    RANK() OVER (PARTITION BY shift ORDER BY total_net_loss DESC) AS loss_rank_by_shift
FROM return_agg
ORDER BY total_net_loss DESC
LIMIT 50
