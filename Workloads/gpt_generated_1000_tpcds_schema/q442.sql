/*
Goal: Identify the top‑ranked items by current price within each class, enriched with a recent‑30‑day inventory quantity metric, while demonstrating advanced SQL features (CTEs, FULL OUTER JOIN, IN subquery, INTERSECT, LATERAL join, window functions, paging).
*/
WITH filtered_inventory AS (
    SELECT
        inv_date_sk,
        inv_item_sk,
        inv_warehouse_sk,
        inv_quantity_on_hand
    FROM inventory
    WHERE inv_warehouse_sk IN (3, 7)                         -- predicate 1
      AND inv_quantity_on_hand > 0                         -- predicate 2
      AND inv_item_sk IN (                                 -- predicate 3 (IN subquery)
          SELECT i_item_sk
          FROM item
          WHERE i_class_id = 5
      )
),
filtered_item AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_rec_start_date,
        i_rec_end_date,
        i_class_id,
        i_current_price
    FROM item
    WHERE i_rec_start_date >= DATE '1999-01-01'          -- predicate 4
      AND i_rec_end_date   <= DATE '2001-12-31'           -- predicate 5
      AND i_class_id IN (1, 5, 13)                        -- predicate 6
),
intersect_keys AS (
    SELECT inv_item_sk AS item_key FROM filtered_inventory
    INTERSECT
    SELECT i_item_sk FROM filtered_item
)
SELECT
    inv.inv_date_sk,
    inv.inv_item_sk,
    inv.inv_warehouse_sk,
    inv.inv_quantity_on_hand,
    itm.i_item_id,
    itm.i_rec_start_date,
    itm.i_rec_end_date,
    itm.i_class_id,
    itm.i_current_price,
    recent.total_qty_last_30,
    ROW_NUMBER() OVER (PARTITION BY itm.i_class_id ORDER BY itm.i_current_price DESC) AS price_rank,
    RANK() OVER (ORDER BY recent.total_qty_last_30 DESC) AS qty_rank
FROM filtered_inventory inv
FULL OUTER JOIN filtered_item itm
    ON inv.inv_item_sk = itm.i_item_sk
CROSS JOIN LATERAL (
    SELECT COALESCE(SUM(inv2.inv_quantity_on_hand), 0) AS total_qty_last_30
    FROM inventory inv2
    WHERE inv2.inv_item_sk = inv.inv_item_sk
      AND inv2.inv_date_sk BETWEEN inv.inv_date_sk - 30 AND inv.inv_date_sk
) AS recent
WHERE (
        inv.inv_item_sk IS NOT NULL
        AND inv.inv_item_sk IN (SELECT item_key FROM intersect_keys)
    )
   OR (
        itm.i_item_sk IS NOT NULL
        AND itm.i_item_sk IN (SELECT item_key FROM intersect_keys)
    )
ORDER BY price_rank ASC, qty_rank DESC
OFFSET 10 ROWS
LIMIT 100
