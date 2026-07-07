WITH
    store_agg AS (
        SELECT ss_item_id AS item_id,
               SUM(ss_quantity) AS store_qty
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_agg AS (
        SELECT ws_item_id AS item_id,
               SUM(ws_quantity) AS web_qty
        FROM web_sales
        GROUP BY ws_item_id
    ),
    item_sales AS (
        SELECT i.i_category,
               COALESCE(s.store_qty, 0) AS store_qty,
               COALESCE(w.web_qty, 0) AS web_qty
        FROM items i
        LEFT JOIN store_agg s ON i.i_item_id = s.item_id
        LEFT JOIN web_agg w ON i.i_item_id = w.item_id
    )
SELECT i_category,
       SUM(store_qty) AS total_store_quantity,
       SUM(web_qty) AS total_web_quantity,
       (SUM(store_qty) + SUM(web_qty)) AS total_quantity
FROM item_sales
GROUP BY i_category
ORDER BY total_quantity DESC
