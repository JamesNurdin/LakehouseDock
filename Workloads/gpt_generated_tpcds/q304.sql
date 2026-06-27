WITH item_inventory AS (
    SELECT
        inventory.inv_warehouse_sk,
        inventory.inv_item_sk,
        inventory.inv_quantity_on_hand,
        item.i_brand,
        item.i_category,
        item.i_current_price,
        (inventory.inv_quantity_on_hand * item.i_current_price) AS inventory_value
    FROM inventory
    JOIN item
        ON inventory.inv_item_sk = item.i_item_sk
    WHERE item.i_current_price > 0
),
warehouse_brand_agg AS (
    SELECT
        warehouse.w_warehouse_name,
        item_inventory.i_brand,
        SUM(item_inventory.inv_quantity_on_hand) AS total_quantity,
        SUM(item_inventory.inventory_value) AS total_inventory_value,
        AVG(item_inventory.i_current_price) AS avg_item_price
    FROM item_inventory
    JOIN warehouse
        ON item_inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
    WHERE warehouse.w_state = 'CA'
    GROUP BY warehouse.w_warehouse_name, item_inventory.i_brand
)
SELECT
    warehouse_brand_agg.w_warehouse_name,
    warehouse_brand_agg.i_brand,
    warehouse_brand_agg.total_quantity,
    warehouse_brand_agg.total_inventory_value,
    warehouse_brand_agg.avg_item_price,
    RANK() OVER (
        PARTITION BY warehouse_brand_agg.w_warehouse_name
        ORDER BY warehouse_brand_agg.total_inventory_value DESC
    ) AS brand_rank
FROM warehouse_brand_agg
ORDER BY warehouse_brand_agg.total_inventory_value DESC
LIMIT 20
