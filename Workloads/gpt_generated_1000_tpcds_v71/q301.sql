WITH item_inventory_agg AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        SUM(inv.inv_quantity_on_hand) AS total_qty
    FROM tpcds.inventory inv
    JOIN tpcds.item i
        ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_warehouse_sk IN (15, 3)
    GROUP BY i.i_item_id, i.i_brand
    HAVING SUM(inv.inv_quantity_on_hand) > 100
)
SELECT
    i_item_id,
    i_brand,
    total_qty,
    'WarehouseGroup1' AS group_label
FROM item_inventory_agg
UNION ALL
SELECT
    i_item_id,
    i_brand,
    total_qty,
    'WarehouseGroup2' AS group_label
FROM (
    SELECT
        i.i_item_id,
        i.i_brand,
        SUM(inv.inv_quantity_on_hand) AS total_qty
    FROM tpcds.inventory inv
    JOIN tpcds.item i
        ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_warehouse_sk IN (2, 20)
    GROUP BY i.i_item_id, i.i_brand
    HAVING SUM(inv.inv_quantity_on_hand) > 50
) grp2
ORDER BY total_qty DESC, i_item_id
LIMIT 100
