WITH per_item AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_class,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS sum_return_amount,
        SUM(cr.cr_return_quantity) AS sum_return_qty,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS sum_inventory_qty
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = 2450962               -- specific inventory snapshot
        AND inv.inv_quantity_on_hand > 600        -- keep only sizable stock rows
    WHERE cr.cr_warehouse_sk IN (3, 5, 7)          -- filter warehouses of interest
      AND i.i_current_price BETWEEN 3 AND 9       -- price range filter
    GROUP BY i.i_item_sk, i.i_brand, i.i_class, r.r_reason_desc
)
SELECT
    per_item.i_brand,
    per_item.i_class,
    per_item.r_reason_desc,
    AVG(per_item.sum_return_amount) AS avg_return_amount,
    SUM(per_item.sum_return_qty) AS total_return_qty,
    COUNT(DISTINCT per_item.i_item_sk) AS distinct_item_count
FROM per_item
WHERE per_item.sum_inventory_qty > 0                     -- ensure we have inventory info
  AND EXISTS (
        SELECT 1
        FROM inventory inv2
        WHERE inv2.inv_item_sk = per_item.i_item_sk
          AND inv2.inv_quantity_on_hand > 800          -- extra stock sanity check
    )
GROUP BY per_item.i_brand, per_item.i_class, per_item.r_reason_desc
HAVING AVG(per_item.sum_return_amount) > 100               -- keep only high‑value reasons
ORDER BY avg_return_amount DESC
LIMIT 10
