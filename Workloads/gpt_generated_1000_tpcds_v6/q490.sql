WITH filtered_inventory AS (
    SELECT
        i.inv_warehouse_sk,
        i.inv_quantity_on_hand,
        w.w_state
    FROM inventory i
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_date_sk = 2450829                     -- filter on a specific date surrogate key
      AND i.inv_quantity_on_hand BETWEEN 10 AND 500   -- filter on realistic quantity range
      AND w.w_city = 'Seattle'                        -- filter on a realistic city value
      AND EXISTS (
          SELECT 1
          FROM warehouse w2
          WHERE w2.w_warehouse_sk = i.inv_warehouse_sk
            AND w2.w_suite_number = 'Suite 160'      -- semi‑join predicate using suite number
      )
),
unioned AS (
    SELECT inv_warehouse_sk, inv_quantity_on_hand, w_state
    FROM filtered_inventory
    WHERE w_state = 'CA'
    UNION ALL
    SELECT inv_warehouse_sk, inv_quantity_on_hand, w_state
    FROM filtered_inventory
    WHERE w_state = 'WA'
),
aggregated AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        AVG(inv_quantity_on_hand) AS avg_qty,
        COUNT(*) AS cnt_rows
    FROM unioned
    GROUP BY inv_warehouse_sk
)
SELECT
    a.inv_warehouse_sk,
    a.total_qty,
    a.avg_qty,
    a.cnt_rows
FROM aggregated a
ORDER BY a.total_qty DESC
LIMIT 100
