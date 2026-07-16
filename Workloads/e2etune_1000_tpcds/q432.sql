WITH recent_inventory AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        inv_quantity_on_hand,
        inv_date_sk
    FROM inventory
    WHERE inv_date_sk BETWEEN 2450900 AND 2451100
),
warehouse_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        w.w_country,
        SUM(ri.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT ri.inv_item_sk) AS distinct_items,
        AVG(ri.inv_quantity_on_hand) AS avg_quantity
    FROM recent_inventory ri
    JOIN warehouse w
        ON ri.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States'
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        w.w_country
),
ranked_warehouses AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_name,
        w_city,
        w_state,
        w_country,
        total_quantity,
        distinct_items,
        avg_quantity,
        ROW_NUMBER() OVER (PARTITION BY w_state ORDER BY total_quantity DESC) AS state_rank
    FROM warehouse_agg
)
SELECT
    w_warehouse_sk,
    w_warehouse_name,
    w_city,
    w_state,
    total_quantity,
    distinct_items,
    avg_quantity,
    state_rank
FROM ranked_warehouses
WHERE state_rank <= 3
ORDER BY w_state, total_quantity DESC
LIMIT 50
