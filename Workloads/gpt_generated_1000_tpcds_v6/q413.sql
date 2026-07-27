WITH sub_a AS (
    SELECT w.w_warehouse_name AS warehouse_name,
           i.i_brand AS brand,
           SUM(inv.inv_quantity_on_hand) AS total_qty
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_brand_id = 3002001
      AND w.w_county = 'Fairfield County'
    GROUP BY w.w_warehouse_name, i.i_brand
    HAVING SUM(inv.inv_quantity_on_hand) > 500
),
sub_b AS (
    SELECT w.w_warehouse_name AS warehouse_name,
           i.i_brand AS brand,
           SUM(inv.inv_quantity_on_hand) AS total_qty
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_brand_id = 6008007
      AND w.w_county = 'Huron County'
    GROUP BY w.w_warehouse_name, i.i_brand
    HAVING SUM(inv.inv_quantity_on_hand) > 500
)
SELECT DISTINCT warehouse_name,
                brand,
                total_qty
FROM (
    SELECT warehouse_name, brand, total_qty FROM sub_a
    UNION ALL
    SELECT warehouse_name, brand, total_qty FROM sub_b
) AS combined
ORDER BY total_qty DESC
LIMIT 100
