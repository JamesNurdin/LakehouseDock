WITH warehouse_totals AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_item_cnt,
        AVG(i.inv_quantity_on_hand) AS avg_quantity
    FROM inventory i
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        w.w_state
)
SELECT
    w_warehouse_id,
    w_warehouse_name,
    w_city,
    w_state,
    total_quantity,
    distinct_item_cnt,
    avg_quantity,
    RANK() OVER (ORDER BY total_quantity DESC) AS warehouse_quantity_rank,
    100.0 * total_quantity / SUM(total_quantity) OVER () AS pct_of_total_quantity
FROM warehouse_totals
ORDER BY total_quantity DESC
LIMIT 20
