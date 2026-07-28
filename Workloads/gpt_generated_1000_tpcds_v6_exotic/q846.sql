WITH inv_subset1 AS (
        SELECT inv_item_sk,
               inv_warehouse_sk,
               SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory
        WHERE inv_date_sk = 2450941
          AND inv_quantity_on_hand > 0
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    inv_subset2 AS (
        SELECT inv_item_sk,
               inv_warehouse_sk,
               SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory
        WHERE inv_date_sk = 2450962
          AND inv_quantity_on_hand > 0
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    combined_inv AS (
        SELECT * FROM inv_subset1
        UNION ALL
        SELECT * FROM inv_subset2
    ),
    agg_inv AS (
        SELECT inv_item_sk,
               inv_warehouse_sk,
               SUM(total_qty) AS total_qty,
               COUNT(*) AS src_cnt
        FROM combined_inv
        GROUP BY inv_item_sk, inv_warehouse_sk
    )
SELECT i.i_item_id,
       w.w_warehouse_name,
       agg_inv.total_qty,
       COUNT(*) OVER (PARTITION BY w.w_state) AS wh_state_item_cnt,
       AVG(i.i_current_price) AS avg_price
FROM agg_inv
JOIN item i ON agg_inv.inv_item_sk = i.i_item_sk
JOIN warehouse w ON agg_inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.i_brand_id IN (2004002, 1004002)
  AND w.w_zip = '29231'
  AND w.w_state = 'AL'
  AND i.i_manager_id = 3
  AND EXISTS (
        SELECT 1
        FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk
          AND inv2.inv_quantity_on_hand > 500
    )
GROUP BY i.i_item_id, w.w_warehouse_name, agg_inv.total_qty, w.w_state
ORDER BY agg_inv.total_qty DESC
LIMIT 100
