WITH warehouse_inventory AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(*) AS item_count
    FROM
        warehouse w
        JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        w.w_warehouse_sq_ft > 600000
        AND w.w_street_type = 'Drive'
        AND i.inv_quantity_on_hand >= 500
        AND i.inv_date_sk >= 2450900
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        w.w_state
)
SELECT
    wi.w_warehouse_id,
    wi.w_warehouse_name,
    wi.w_city,
    wi.w_state,
    wi.total_quantity_on_hand,
    wi.item_count,
    CASE
        WHEN wi.total_quantity_on_hand > (SELECT avg(total_quantity_on_hand) FROM warehouse_inventory) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS avg_comparison,
    RANK() OVER (PARTITION BY wi.w_state ORDER BY wi.total_quantity_on_hand DESC) AS state_rank,
    SUM(wi.total_quantity_on_hand) OVER (PARTITION BY wi.w_state ORDER BY wi.total_quantity_on_hand ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_state_quantity
FROM
    warehouse_inventory wi
WHERE
    EXISTS (
        SELECT 1
        FROM inventory i2
        WHERE i2.inv_warehouse_sk = wi.w_warehouse_sk
          AND i2.inv_quantity_on_hand > 800
    )
ORDER BY
    wi.w_state,
    state_rank
LIMIT 100
