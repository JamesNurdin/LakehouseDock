WITH min_dates AS (
    SELECT inv_item_sk, MIN(inv_date_sk) AS min_date
    FROM inventory
    GROUP BY inv_item_sk
),
max_dates AS (
    SELECT inv_item_sk, MAX(inv_date_sk) AS max_date
    FROM inventory
    GROUP BY inv_item_sk
),
earliest_qty AS (
    SELECT i.inv_item_sk, i.inv_warehouse_sk, i.inv_quantity_on_hand AS earliest_qty
    FROM inventory i
    JOIN min_dates md ON i.inv_item_sk = md.inv_item_sk AND i.inv_date_sk = md.min_date
),
latest_qty AS (
    SELECT i.inv_item_sk, i.inv_warehouse_sk, i.inv_quantity_on_hand AS latest_qty
    FROM inventory i
    JOIN max_dates mx ON i.inv_item_sk = mx.inv_item_sk AND i.inv_date_sk = mx.max_date
),
warehouse_avg AS (
    SELECT inv_warehouse_sk, AVG(inv_quantity_on_hand) AS avg_qty
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    l.inv_item_sk,
    l.inv_warehouse_sk,
    l.latest_qty,
    e.earliest_qty,
    (l.latest_qty - e.earliest_qty) AS delta_qty,
    wa.avg_qty
FROM latest_qty l
JOIN earliest_qty e
    ON l.inv_item_sk = e.inv_item_sk
    AND l.inv_warehouse_sk = e.inv_warehouse_sk
JOIN warehouse_avg wa
    ON l.inv_warehouse_sk = wa.inv_warehouse_sk
WHERE (l.latest_qty - e.earliest_qty) > 0
ORDER BY delta_qty DESC
LIMIT 10
