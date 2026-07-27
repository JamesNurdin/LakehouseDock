WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        COUNT(DISTINCT inv_item_sk) AS distinct_items,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM tpcds.inventory
    WHERE inv_quantity_on_hand > 500                     -- predicate 1
      AND inv_item_sk IN (8, 13, 19)                     -- predicate 2 (sample values)
    GROUP BY inv_warehouse_sk
)
SELECT
    sub.w_state,
    SUM(sub.total_qty) AS state_total_qty,
    AVG(sub.distinct_items) AS avg_distinct_items,
    COUNT(DISTINCT sub.w_warehouse_id) AS warehouse_cnt,
    MAX(sub.high_qty_item_count) AS max_high_qty_items
FROM (
    SELECT
        w.w_state AS w_state,
        w.w_warehouse_id,
        ia.total_qty,
        ia.distinct_items,
        (
            SELECT COUNT(*)
            FROM tpcds.inventory i2
            WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
              AND i2.inv_quantity_on_hand > 800          -- predicate inside scalar subquery
        ) AS high_qty_item_count
    FROM inv_agg ia
    JOIN tpcds.warehouse w
      ON ia.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_zip IN ('64593', '55709')               -- predicate 3 (sample values)
      AND w.w_city IS NOT NULL                       -- predicate 4
      AND w.w_suite_number <> 'Suite 0'               -- predicate 5
) sub
GROUP BY sub.w_state
HAVING SUM(sub.total_qty) > 2000                      -- filter on aggregated result
ORDER BY state_total_qty DESC
LIMIT 100
