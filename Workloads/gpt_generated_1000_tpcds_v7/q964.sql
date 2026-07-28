WITH warehouse_returns AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_ship_cost) AS avg_ship_cost
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 50
      AND w.w_city IN ('Fairview', 'Riverside', 'Salem')
    GROUP BY w.w_warehouse_id, w.w_city, w.w_state
)
SELECT
    w_warehouse_id,
    w_city,
    w_state,
    total_return_amount,
    total_net_loss,
    return_cnt,
    CASE
        WHEN total_return_amount > 1000 THEN 'High'
        ELSE 'Low'
    END AS return_level,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
    ROW_NUMBER() OVER (PARTITION BY w_state ORDER BY total_return_amount DESC) AS rn_state
FROM warehouse_returns
ORDER BY net_loss_rank
LIMIT 10
