WITH warehouse_item_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_state,
        i.i_category,
        i.i_brand,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        AVG(i.i_current_price) AS avg_price,
        AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_current_price > 100
      AND w.w_state IN ('CA', 'TX', 'NY')
    GROUP BY w.w_warehouse_id, w.w_state, i.i_category, i.i_brand
)
SELECT
    w_warehouse_id,
    w_state,
    i_category,
    i_brand,
    total_qty,
    avg_price,
    avg_wholesale_cost,
    distinct_items,
    RANK() OVER (PARTITION BY w_warehouse_id ORDER BY total_qty DESC) AS category_rank
FROM warehouse_item_agg
WHERE total_qty > 5000
ORDER BY w_warehouse_id, category_rank
LIMIT 100
