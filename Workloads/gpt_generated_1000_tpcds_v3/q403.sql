WITH filtered_inventory AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        itm.i_item_id,
        itm.i_brand,
        itm.i_current_price,
        itm.i_manager_id,
        itm.i_container,
        itm.i_rec_start_date
    FROM inventory inv
    JOIN item itm
        ON inv.inv_item_sk = itm.i_item_sk
    WHERE inv.inv_date_sk IN (2450969, 2450955, 2451081)
      AND inv.inv_warehouse_sk = 12
      AND itm.i_brand_id IN (2004001, 6008007)
      AND itm.i_manager_id = 25
      AND itm.i_container = 'Unknown'
      AND itm.i_rec_start_date >= DATE '1998-01-01'
)
SELECT
    filtered_inventory.inv_date_sk,
    filtered_inventory.inv_item_sk,
    filtered_inventory.inv_warehouse_sk,
    filtered_inventory.inv_quantity_on_hand,
    filtered_inventory.i_item_id,
    filtered_inventory.i_brand,
    filtered_inventory.i_current_price,
    filtered_inventory.i_manager_id,
    filtered_inventory.i_container,
    filtered_inventory.i_rec_start_date,
    CASE
        WHEN filtered_inventory.inv_quantity_on_hand >= 500 THEN 'High'
        ELSE 'Low'
    END AS quantity_category,
    ROW_NUMBER() OVER (
        PARTITION BY filtered_inventory.inv_warehouse_sk
        ORDER BY filtered_inventory.inv_quantity_on_hand DESC
    ) AS warehouse_quantity_rank,
    SUM(filtered_inventory.inv_quantity_on_hand) OVER (
        PARTITION BY filtered_inventory.inv_warehouse_sk
        ORDER BY filtered_inventory.inv_date_sk
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_qty_sum_3
FROM filtered_inventory
WHERE EXISTS (
    SELECT 1
    FROM item itm2
    WHERE itm2.i_item_sk = filtered_inventory.inv_item_sk
      AND itm2.i_brand_id = 2004001
)
ORDER BY filtered_inventory.inv_warehouse_sk,
         warehouse_quantity_rank
LIMIT 100
