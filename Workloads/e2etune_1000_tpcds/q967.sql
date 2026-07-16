WITH agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        d_ret.d_year,
        d_ret.d_moy AS month_of_year,
        sm.sm_type AS ship_mode_type,
        w.w_state AS warehouse_state,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_class = 'large'
      AND d_ret.d_year = 2002
      AND sm.sm_type IN ('AIR', 'GROUND')
      AND cr.cr_return_amount > 0
      AND d_open.d_date > DATE '2000-01-01'
    GROUP BY
        cc.cc_name,
        d_ret.d_year,
        d_ret.d_moy,
        sm.sm_type,
        w.w_state
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
    call_center_name,
    d_year,
    month_of_year,
    ship_mode_type,
    warehouse_state,
    total_return_amount,
    total_net_loss,
    avg_return_qty,
    return_count,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS rank_by_year
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
