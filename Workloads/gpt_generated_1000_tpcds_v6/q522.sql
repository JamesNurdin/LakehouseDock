WITH warehouse_returns AS (
    SELECT
        w.w_warehouse_id,
        w.w_state,
        w.w_city,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_returned,
        CASE
            WHEN SUM(cr.cr_return_amount) > 2000 THEN 'HIGH'
            ELSE 'LOW'
        END AS return_category
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
        AND w.w_city IN ('Spring', 'Ridge')
        AND cr.cr_call_center_sk IN (10, 19)
        AND cr.cr_reversed_charge > 50
        AND i.inv_quantity_on_hand > 0
    GROUP BY w.w_warehouse_id, w.w_state, w.w_city
)
SELECT
    wr.w_warehouse_id,
    wr.w_state,
    wr.w_city,
    wr.total_return_amount,
    wr.total_return_quantity,
    wr.total_inventory_on_hand,
    wr.return_category,
    AVG(wr.total_return_amount) OVER (PARTITION BY wr.w_state) AS avg_state_return_amount,
    SUM(wr.total_return_amount) OVER (
        ORDER BY wr.total_return_amount DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_amount,
    RANK() OVER (ORDER BY wr.total_return_amount DESC) AS revenue_rank
FROM warehouse_returns wr
WHERE wr.total_return_amount > 500
ORDER BY wr.total_return_amount DESC
LIMIT 100
