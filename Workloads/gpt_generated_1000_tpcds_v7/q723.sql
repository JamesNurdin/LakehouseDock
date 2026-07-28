WITH joined_data AS (
    SELECT
        cr.cr_warehouse_sk,
        w.w_state,
        w.w_warehouse_name,
        t.t_hour,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_quantity,
        inv.inv_quantity_on_hand,
        cr.cr_order_number
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        cr.cr_return_quantity > 1
        AND cr.cr_return_amount >= 10.00
        AND cr.cr_return_tax < 5.00
        AND cr.cr_warehouse_sk IN (1, 12, 18)
        AND t.t_hour BETWEEN 8 AND 17
        AND w.w_zip = '35709'
        AND inv.inv_quantity_on_hand > 100
),
agg AS (
    SELECT
        w_state,
        w_warehouse_name,
        t_hour,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_tax) AS avg_return_tax,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
        COUNT(DISTINCT cr_order_number) AS distinct_orders
    FROM joined_data
    GROUP BY w_state, w_warehouse_name, t_hour
)
SELECT
    w_state,
    w_warehouse_name,
    t_hour,
    total_return_amount,
    avg_return_tax,
    total_return_qty,
    total_inventory_on_hand,
    distinct_orders,
    SUM(total_return_amount) OVER (
        PARTITION BY w_state
        ORDER BY total_return_amount DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_by_state
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
