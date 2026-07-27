WITH agg_returns AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_state,
        w.w_warehouse_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_quantity) AS avg_return_qty
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cc.cc_employees > 1000000
      AND td.t_sub_shift = 'morning'
      AND c.c_birth_day BETWEEN 1 AND 20
    GROUP BY cc.cc_call_center_id, cc.cc_state, w.w_warehouse_name
)
SELECT
    ar.cc_call_center_id,
    ar.cc_state,
    ar.w_warehouse_name,
    ar.total_return_amount,
    ar.total_net_loss,
    ar.return_cnt,
    ar.avg_return_qty,
    AVG(ar.total_return_amount) OVER (PARTITION BY ar.cc_state) AS avg_return_amount_state,
    ROW_NUMBER() OVER (PARTITION BY ar.cc_state ORDER BY ar.total_return_amount DESC) AS rn_state
FROM agg_returns ar
WHERE ar.total_net_loss > (
    SELECT MAX(total_net_loss) * 0.5 FROM agg_returns
)
ORDER BY ar.total_return_amount DESC
LIMIT 100
