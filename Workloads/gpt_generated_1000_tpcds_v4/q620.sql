WITH warehouse_stats AS (
    SELECT
        w.w_warehouse_sk,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(cr.cr_return_quantity) AS total_qty
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_quantity > 1
    GROUP BY w.w_warehouse_sk
)
SELECT
    cr.cr_order_number,
    w.w_warehouse_id,
    w.w_warehouse_name,
    cr.cr_return_amount,
    cr.cr_net_loss,
    CASE
        WHEN cr.cr_net_loss > 1000 THEN 'HIGH'
        WHEN cr.cr_net_loss > 100 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category,
    ws.avg_return_amount,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY cr.cr_return_amount DESC) AS rn
FROM catalog_returns cr
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN warehouse_stats ws
    ON ws.w_warehouse_sk = w.w_warehouse_sk
WHERE
    cr.cr_return_amount > 100
    AND cr.cr_store_credit < 500
    AND cr.cr_reversed_charge BETWEEN 10 AND 400
    AND w.w_warehouse_sq_ft BETWEEN 500000 AND 1000000
    AND w.w_county IN ('Bronx County', 'Huron County')
    AND EXISTS (
        SELECT 1
        FROM warehouse w2
        WHERE w2.w_state = 'CA'
          AND w2.w_warehouse_sk = cr.cr_warehouse_sk
    )
ORDER BY cr.cr_return_amount DESC
LIMIT 100
