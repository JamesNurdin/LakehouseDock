WITH inventory_by_warehouse AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        w.w_country,
        i.inv_item_sk,
        i.inv_quantity_on_hand
    FROM inventory i
    JOIN warehouse w
      ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand > 0
),
warehouse_totals AS (
    SELECT
        ibw.w_warehouse_sk,
        ibw.w_warehouse_id,
        ibw.w_warehouse_name,
        ibw.w_city,
        ibw.w_state,
        ibw.w_country,
        SUM(ibw.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT ibw.inv_item_sk) AS distinct_items
    FROM inventory_by_warehouse ibw
    GROUP BY ibw.w_warehouse_sk, ibw.w_warehouse_id, ibw.w_warehouse_name,
             ibw.w_city, ibw.w_state, ibw.w_country
),
inventory_ratios AS (
    SELECT
        ibw.w_warehouse_id,
        ibw.w_warehouse_name,
        ibw.w_city,
        ibw.w_state,
        ibw.w_country,
        ibw.inv_item_sk,
        ibw.inv_quantity_on_hand,
        wt.total_qty,
        CAST(ibw.inv_quantity_on_hand AS double) / wt.total_qty AS qty_ratio
    FROM inventory_by_warehouse ibw
    JOIN warehouse_totals wt
      ON ibw.w_warehouse_sk = wt.w_warehouse_sk
)
SELECT
    ir.w_warehouse_id,
    ir.w_warehouse_name,
    ir.w_city,
    ir.w_state,
    ir.w_country,
    COUNT(DISTINCT ir.inv_item_sk) AS distinct_item_count,
    SUM(ir.inv_quantity_on_hand) AS total_quantity_on_hand,
    AVG(ir.qty_ratio) AS avg_quantity_ratio,
    MAX(ir.qty_ratio) AS max_quantity_ratio,
    MIN(ir.qty_ratio) AS min_quantity_ratio
FROM inventory_ratios ir
GROUP BY ir.w_warehouse_id, ir.w_warehouse_name, ir.w_city, ir.w_state, ir.w_country
ORDER BY total_quantity_on_hand DESC
LIMIT 10
