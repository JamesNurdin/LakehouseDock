WITH item_totals AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT inv_warehouse_sk) AS warehouse_cnt,
        RANK() OVER (ORDER BY SUM(inv_quantity_on_hand) DESC) AS qty_rank
    FROM inventory
    GROUP BY inv_item_sk
    HAVING SUM(inv_quantity_on_hand) > 1000
)
SELECT
    i.inv_item_sk,
    i.inv_warehouse_sk,
    i.inv_quantity_on_hand,
    it.total_qty,
    it.warehouse_cnt,
    it.qty_rank,
    (i.inv_quantity_on_hand * 1.0 / it.total_qty) AS pct_of_total
FROM inventory i
JOIN item_totals it
    ON i.inv_item_sk = it.inv_item_sk
WHERE i.inv_quantity_on_hand > 0
ORDER BY it.qty_rank, i.inv_warehouse_sk
LIMIT 100
