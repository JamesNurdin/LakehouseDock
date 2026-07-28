WITH inv_item AS (
    SELECT
        i.inv_warehouse_sk,
        i.inv_item_sk,
        i.inv_quantity_on_hand,
        it.i_item_id,
        it.i_brand,
        it.i_category,
        it.i_class_id,
        it.i_formulation,
        it.i_container
    FROM inventory AS i
    JOIN item AS it
        ON i.inv_item_sk = it.i_item_sk
    WHERE i.inv_warehouse_sk IN (7, 10, 12, 18)                      -- predicate 1
      AND i.inv_date_sk BETWEEN 2450800 AND 2451100                 -- predicate 2
      AND it.i_class_id = 6                                         -- predicate 3
      AND it.i_container = 'Unknown'                                -- predicate 4
      AND it.i_formulation LIKE '%blue%'                            -- predicate 5
)
SELECT
    inv_warehouse_sk,
    inv_item_sk,
    i_item_id,
    i_brand,
    i_category,
    SUM(inv_quantity_on_hand) AS total_qty,
    ROW_NUMBER() OVER (
        PARTITION BY inv_warehouse_sk
        ORDER BY SUM(inv_quantity_on_hand) DESC
    ) AS warehouse_item_rank,
    RANK() OVER (
        ORDER BY SUM(inv_quantity_on_hand) DESC
    ) AS global_qty_rank,
    CASE
        WHEN SUM(inv_quantity_on_hand) > 1000 THEN 'High Stock'
        WHEN SUM(inv_quantity_on_hand) BETWEEN 500 AND 1000 THEN 'Medium Stock'
        ELSE 'Low Stock'
    END AS stock_level
FROM inv_item
GROUP BY
    inv_warehouse_sk,
    inv_item_sk,
    i_item_id,
    i_brand,
    i_category
ORDER BY
    inv_warehouse_sk,
    warehouse_item_rank
