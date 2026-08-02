WITH inv_daily AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(*) AS inv_rows
    FROM inventory
    WHERE inv_quantity_on_hand > 500                       -- filter predicate 1
      AND inv_date_sk BETWEEN 2450800 AND 2451100           -- filter predicate 2
    GROUP BY inv_warehouse_sk, inv_date_sk
),
inv_per_warehouse AS (
    SELECT
        inv_warehouse_sk,
        SUM(total_qty) AS warehouse_qty,
        SUM(inv_rows) AS warehouse_rows
    FROM inv_daily
    GROUP BY inv_warehouse_sk
),
warehouse_filtered AS (
    SELECT *
    FROM warehouse
    WHERE w_state = 'CA'                                    -- filter predicate 3
      AND w_zip IN ('89275', '46098')
      AND w_county = 'Richland County'
),
warehouse_rollup AS (
    SELECT
        w.w_state,
        w.w_city,
        w.w_warehouse_id,
        SUM(wh.warehouse_qty) AS total_quantity,
        SUM(wh.warehouse_rows) AS inventory_rows
    FROM warehouse_filtered w
    LEFT JOIN inv_per_warehouse wh
        ON w.w_warehouse_sk = wh.inv_warehouse_sk
    GROUP BY ROLLUP (w.w_state, w.w_city, w.w_warehouse_id)
)
SELECT
    w_state,
    w_city,
    w_warehouse_id,
    total_quantity,
    inventory_rows,
    RANK() OVER (ORDER BY total_quantity DESC NULLS LAST) AS qty_rank,
    CASE
        WHEN total_quantity > (
            SELECT AVG(warehouse_qty)
            FROM (
                SELECT SUM(inv_quantity_on_hand) AS warehouse_qty
                FROM inventory
                GROUP BY inv_warehouse_sk
            ) AS overall
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS quantity_category
FROM warehouse_rollup
ORDER BY total_quantity DESC NULLS LAST, w_state, w_city
LIMIT 100
