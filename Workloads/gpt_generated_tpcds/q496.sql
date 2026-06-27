WITH warehouse_return_summary AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        t.t_shift,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_tax) AS total_return_tax,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        AVG(cr.cr_return_quantity) AS avg_return_quantity
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE t.t_shift = 'AM'
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, t.t_shift
)
SELECT
    w_warehouse_name,
    t_shift,
    total_return_amount,
    total_return_tax,
    total_net_loss,
    return_count,
    avg_return_quantity,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank,
    SUM(total_return_amount) OVER (
        ORDER BY total_return_amount DESC
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_return_amount
FROM warehouse_return_summary
ORDER BY total_return_amount DESC
LIMIT 10
