WITH catalog_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        cr.cr_ship_mode_sk,
        COUNT(*) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_fee) AS avg_fee
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_warehouse_sk IN (7, 14, 9)
      AND cr.cr_return_amount > 500
      AND cr.cr_ship_mode_sk IN (9, 4)
    GROUP BY w.w_warehouse_id, w.w_city, w.w_state, cr.cr_ship_mode_sk
    HAVING COUNT(*) >= 5
)
SELECT
    ca.w_warehouse_id,
    ca.w_city,
    ca.w_state,
    ca.cr_ship_mode_sk,
    ca.total_returns,
    ca.total_return_amount,
    ca.total_net_loss,
    ca.avg_fee,
    (ca.total_return_amount / NULLIF((SELECT SUM(wr.wr_return_amt_inc_tax) FROM web_returns wr WHERE wr.wr_return_quantity > 2), 0)) AS return_to_web_return_ratio,
    RANK() OVER (ORDER BY ca.total_net_loss DESC) AS loss_rank
FROM catalog_agg ca
ORDER BY ca.total_net_loss DESC
LIMIT 50
