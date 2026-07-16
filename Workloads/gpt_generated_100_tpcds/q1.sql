WITH warehouse_returns AS (
    SELECT
        cr.cr_warehouse_sk,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns AS cr
    WHERE cr.cr_return_quantity > 0
    GROUP BY cr.cr_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    wr.total_return_qty,
    wr.total_return_amount,
    wr.total_net_loss,
    wr.return_cnt,
    wr.total_return_amount / NULLIF(wr.return_cnt, 0) AS avg_return_amount_per_return
FROM warehouse_returns AS wr
JOIN warehouse AS w
    ON wr.cr_warehouse_sk = w.w_warehouse_sk
ORDER BY wr.total_net_loss DESC
LIMIT 10
