WITH filtered_inventory AS (
   SELECT inv.inv_date_sk,
          inv.inv_item_sk,
          inv.inv_warehouse_sk,
          inv.inv_quantity_on_hand
   FROM inventory inv
   WHERE inv.inv_quantity_on_hand > 0
     AND inv.inv_warehouse_sk IN (1, 6, 11)
     AND inv.inv_item_sk IN (
         SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 500
         EXCEPT
         SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 1000
     )
),
date_filtered AS (
   SELECT d_date_sk,
          d_date,
          d_year,
          d_month_seq,
          d_week_seq
   FROM date_dim
   WHERE d_year = 1999
     AND d_month_seq BETWEEN 1200 AND 1300
     AND d_week_seq IN (10, 11, 12)
),
item_filtered AS (
   SELECT i_item_sk,
          i_item_id,
          i_current_price,
          i_manufact,
          i_brand
   FROM item
   WHERE i_current_price > 50
     AND i_manufact = 'barprically'
     AND i_brand = 'ableanti'
)
SELECT
    fi.inv_item_sk,
    i.i_item_id,
    i.i_current_price,
    d.d_date,
    d.d_year,
    fi.inv_warehouse_sk,
    fi.inv_quantity_on_hand,
    lateral_sum.total_qty_by_item_date,
    LAG(fi.inv_quantity_on_hand) OVER (PARTITION BY fi.inv_item_sk ORDER BY d.d_date) AS prev_qty,
    SUM(fi.inv_quantity_on_hand) OVER (PARTITION BY fi.inv_item_sk) AS running_qty
FROM filtered_inventory fi
FULL OUTER JOIN date_filtered d
     ON fi.inv_date_sk = d.d_date_sk
JOIN item_filtered i
     ON fi.inv_item_sk = i.i_item_sk
CROSS JOIN LATERAL (
    SELECT SUM(inv_quantity_on_hand) AS total_qty_by_item_date
    FROM inventory inv_l
    WHERE inv_l.inv_item_sk = fi.inv_item_sk
      AND inv_l.inv_date_sk = fi.inv_date_sk
) AS lateral_sum
WHERE EXISTS (
    SELECT 1
    FROM inventory inv2
    WHERE inv2.inv_item_sk = fi.inv_item_sk
      AND inv2.inv_quantity_on_hand > fi.inv_quantity_on_hand
)
ORDER BY lateral_sum.total_qty_by_item_date DESC
OFFSET 10
LIMIT 100
