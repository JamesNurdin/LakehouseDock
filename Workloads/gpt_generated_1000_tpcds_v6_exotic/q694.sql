/* goal: Compare inventory levels for items stocked in warehouses located in two different counties, categorizing the quantity level of each item */
WITH high_qty AS (
    SELECT
        i.inv_item_sk,
        w.w_warehouse_name,
        i.inv_quantity_on_hand,
        CASE WHEN i.inv_quantity_on_hand > 200 THEN 'High' ELSE 'Normal' END AS quantity_category
    FROM tpcds.inventory i
    JOIN tpcds.warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand > 100
      AND w.w_county = 'Richland County'
),
low_qty AS (
    SELECT
        i.inv_item_sk,
        w.w_warehouse_name,
        i.inv_quantity_on_hand,
        CASE WHEN i.inv_quantity_on_hand > 200 THEN 'High' ELSE 'Normal' END AS quantity_category
    FROM tpcds.inventory i
    JOIN tpcds.warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand <= 100
      AND w.w_county = 'Marshall County'
)
SELECT
    inv_item_sk,
    w_warehouse_name,
    inv_quantity_on_hand,
    quantity_category
FROM high_qty
UNION ALL
SELECT
    inv_item_sk,
    w_warehouse_name,
    inv_quantity_on_hand,
    quantity_category
FROM low_qty
ORDER BY quantity_category, inv_item_sk
LIMIT 100
