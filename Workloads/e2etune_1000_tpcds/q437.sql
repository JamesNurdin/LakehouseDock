WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT inv_item_sk) AS distinct_items
    FROM inventory
    WHERE inv_quantity_on_hand > 0
      AND inv_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY inv_warehouse_sk, inv_date_sk
),
warehouse_totals AS (
    SELECT
        w.w_warehouse_sk AS warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        w.w_country,
        SUM(ia.total_qty) AS warehouse_total_qty,
        AVG(ia.total_qty) AS avg_daily_qty,
        SUM(ia.distinct_items) AS total_distinct_items
    FROM inv_agg ia
    JOIN warehouse w
        ON ia.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_city, w.w_state, w.w_country
),
ranked_warehouses AS (
    SELECT
        warehouse_sk,
        w_warehouse_name,
        w_city,
        w_state,
        w_country,
        warehouse_total_qty,
        avg_daily_qty,
        total_distinct_items,
        ROW_NUMBER() OVER (ORDER BY warehouse_total_qty DESC) AS warehouse_rank,
        SUM(warehouse_total_qty) OVER (PARTITION BY w_state) AS state_total_qty
    FROM warehouse_totals
)
SELECT
    warehouse_sk,
    w_warehouse_name,
    w_city,
    w_state,
    warehouse_total_qty,
    avg_daily_qty,
    total_distinct_items,
    warehouse_rank,
    state_total_qty
FROM ranked_warehouses
WHERE w_country = 'United States'
  AND warehouse_total_qty > 10000
  AND state_total_qty > 50000
ORDER BY warehouse_rank
LIMIT 20
