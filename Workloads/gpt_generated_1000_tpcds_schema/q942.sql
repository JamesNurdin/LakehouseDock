WITH
  inv_agg AS (
    SELECT
      inv_item_sk,
      SUM(inv_quantity_on_hand) AS total_qty,
      AVG(inv_quantity_on_hand) AS avg_qty,
      MIN(inv_quantity_on_hand) AS min_qty,
      MAX(inv_quantity_on_hand) AS max_qty,
      COUNT(DISTINCT inv_warehouse_sk) AS warehouse_cnt
    FROM inventory
    WHERE inv_warehouse_sk IN (3, 6, 9)
      AND inv_date_sk BETWEEN 2450900 AND 2451100
    GROUP BY inv_item_sk
  ),
  item_filtered AS (
    SELECT
      i_item_sk,
      i_item_id,
      i_current_price,
      i_manufact_id,
      i_rec_start_date,
      i_rec_end_date
    FROM item
    WHERE i_manufact_id IN (220, 460, 625)
      AND i_current_price BETWEEN 10 AND 100
      AND i_rec_start_date >= DATE '1999-01-01'
  ),
  intersect_items AS (
    SELECT i_item_sk FROM item_filtered WHERE i_current_price < 50
    INTERSECT
    SELECT i_item_sk FROM item_filtered WHERE i_manufact_id = 460
  )
SELECT
  it.i_item_id,
  it.i_current_price,
  ia.total_qty,
  ia.avg_qty,
  ia.min_qty,
  ia.max_qty,
  ia.warehouse_cnt,
  (
    SELECT SUM(inv_quantity_on_hand)
    FROM inventory inv2
    WHERE inv2.inv_item_sk = ia.inv_item_sk
  ) AS overall_qty_across_all_warehouses
FROM inv_agg ia
JOIN item_filtered it ON ia.inv_item_sk = it.i_item_sk
JOIN intersect_items ii ON it.i_item_sk = ii.i_item_sk
WHERE it.i_rec_end_date > DATE '2000-01-01'
ORDER BY ia.total_qty DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
