WITH agg_inventory AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 0
      AND inv_date_sk BETWEEN 2450800 AND 2451100
      AND inv_warehouse_sk IN (16, 18, 19)
    GROUP BY inv_item_sk, inv_warehouse_sk
),
missing_items AS (
    SELECT i_item_sk
    FROM item
    EXCEPT
    SELECT inv_item_sk
    FROM inventory
),
full_inventory_items AS (
    SELECT
        ai.inv_item_sk,
        ai.inv_warehouse_sk,
        ai.total_qty,
        i.i_brand,
        i.i_category
    FROM agg_inventory ai
    FULL OUTER JOIN item i
        ON ai.inv_item_sk = i.i_item_sk
)
SELECT
    fii.i_brand,
    fii.i_category,
    w.w_state,
    SUM(fii.total_qty) AS sum_qty,
    COUNT(DISTINCT fii.inv_item_sk) AS distinct_items,
    CASE
        WHEN SUM(fii.total_qty) >= 1000 THEN 'High'
        WHEN SUM(fii.total_qty) >= 500 THEN 'Medium'
        ELSE 'Low'
    END AS qty_category,
    lp.latest_price
FROM full_inventory_items fii
JOIN warehouse w
    ON fii.inv_warehouse_sk = w.w_warehouse_sk
CROSS JOIN LATERAL (
    SELECT i_current_price AS latest_price
    FROM item i2
    WHERE i2.i_item_sk = fii.inv_item_sk
    ORDER BY i2.i_rec_start_date DESC
    LIMIT 1
) lp
WHERE w.w_state IN ('CA', 'TX', 'NY')
  AND w.w_city LIKE '%York%'
  AND fii.i_category = 'Electronics'
GROUP BY CUBE (fii.i_brand, fii.i_category, w.w_state, lp.latest_price)
HAVING SUM(fii.total_qty) > 200
ORDER BY sum_qty DESC
LIMIT 100
