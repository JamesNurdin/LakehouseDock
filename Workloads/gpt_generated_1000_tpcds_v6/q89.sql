WITH returns_summary AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_state,
        w.w_warehouse_name,
        w.w_state AS warehouse_state,
        d_ret.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_ship_cost) AS avg_ship_cost,
        COUNT(*) AS return_cnt,
        SUM(CASE WHEN cr.cr_net_loss > 1000 THEN cr.cr_net_loss ELSE 0 END) AS high_loss_sum,
        MAX(cr.cr_return_quantity) AS max_return_qty
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND cc.cc_state = 'CA'
      AND w.w_state = 'TX'
      AND wp.wp_link_count >= 10
      AND cr.cr_return_quantity > 30
      AND d_cc_closed.d_current_quarter = 'Y'
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_state,
        w.w_warehouse_name,
        w.w_state,
        d_ret.d_year
)
SELECT
    cc_call_center_id,
    cc_state,
    w_warehouse_name,
    warehouse_state,
    d_year,
    total_return_amount,
    avg_ship_cost,
    return_cnt,
    high_loss_sum,
    max_return_qty,
    CASE
        WHEN total_return_amount > 50000 THEN 'HIGH'
        WHEN total_return_amount > 20000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_level
FROM returns_summary
ORDER BY total_return_amount DESC
LIMIT 100
