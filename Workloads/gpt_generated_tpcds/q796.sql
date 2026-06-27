WITH returns_by_center_hour AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        td.t_hour,
        SUM(cr.cr_return_quantity) AS total_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cc.cc_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY cc.cc_call_center_sk, cc.cc_name, cc.cc_state, td.t_hour
)
SELECT
    cc_name,
    cc_state,
    t_hour,
    total_quantity,
    total_return_amount,
    total_net_loss,
    distinct_orders,
    rank() OVER (PARTITION BY t_hour ORDER BY total_net_loss DESC) AS net_loss_rank
FROM returns_by_center_hour
ORDER BY t_hour, net_loss_rank
