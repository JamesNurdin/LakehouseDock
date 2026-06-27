WITH warehouse_returns AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_quantity
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 0
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_city, w.w_state
)
SELECT
    w_warehouse_sk,
    w_warehouse_name,
    w_city,
    w_state,
    total_return_amount,
    total_net_loss,
    return_count,
    avg_return_amount,
    avg_return_quantity,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
    total_net_loss * 100.0 / SUM(total_net_loss) OVER () AS net_loss_pct
FROM warehouse_returns
ORDER BY net_loss_pct DESC
LIMIT 10
