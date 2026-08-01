WITH high_inventory AS (
    SELECT inv_item_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 50
),
low_cost_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_wholesale_cost < 1.00
),
eligible_items AS (
    SELECT inv_item_sk
    FROM high_inventory
    EXCEPT
    SELECT i_item_sk FROM low_cost_items
),
joined_data AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_class,
        i.i_rec_start_date,
        inv.inv_quantity_on_hand,
        inv.inv_warehouse_sk,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY inv.inv_quantity_on_hand DESC) AS brand_qty_rank
    FROM inventory inv
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    JOIN eligible_items ei
        ON inv.inv_item_sk = ei.inv_item_sk
    WHERE i.i_class = 'accessories'
      AND i.i_rec_start_date >= DATE '1999-01-01'
      AND inv.inv_warehouse_sk IN (1, 6, 8)
)
SELECT DISTINCT
    i_item_id,
    i_product_name,
    i_brand,
    i_class,
    inv_quantity_on_hand,
    brand_qty_rank
FROM joined_data
WHERE brand_qty_rank <= 5
ORDER BY i_brand, brand_qty_rank
LIMIT 100
