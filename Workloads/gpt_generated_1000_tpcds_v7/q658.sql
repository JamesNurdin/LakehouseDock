WITH warehouse_category_qty AS (
    SELECT
        inv.inv_warehouse_sk,
        itm.i_category,
        itm.i_category_id,
        SUM(inv.inv_quantity_on_hand) AS total_qty
    FROM inventory AS inv
    JOIN item AS itm
        ON inv.inv_item_sk = itm.i_item_sk
    WHERE itm.i_category_id IN (1, 5, 9)
      AND itm.i_color IN ('yellow', 'pink', 'smoke')
      AND inv.inv_warehouse_sk BETWEEN 4 AND 9
    GROUP BY inv.inv_warehouse_sk, itm.i_category, itm.i_category_id
)
SELECT
    wc.i_category,
    wc.i_category_id,
    AVG(wc.total_qty) AS avg_qty_per_warehouse,
    COUNT(*) AS warehouse_count
FROM warehouse_category_qty AS wc
WHERE wc.total_qty > 500
GROUP BY wc.i_category, wc.i_category_id
HAVING AVG(wc.total_qty) > 600
ORDER BY avg_qty_per_warehouse DESC
