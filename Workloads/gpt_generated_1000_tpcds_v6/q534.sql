WITH recent_inventory AS (
    SELECT
        w.w_city,
        w.w_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        (SELECT MAX(i2.inv_quantity_on_hand)
         FROM inventory i2
         WHERE i2.inv_warehouse_sk = w.w_warehouse_sk) AS max_qty_warehouse
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_date_sk BETWEEN 2450920 AND 2450950
      AND w.w_city IN ('Liberty', 'Pine Grove')
      AND EXISTS (
          SELECT 1
          FROM inventory i3
          WHERE i3.inv_item_sk = i.inv_item_sk
            AND i3.inv_quantity_on_hand > 500
      )
    GROUP BY w.w_city, w.w_warehouse_sk
),
older_inventory AS (
    SELECT
        w.w_city,
        w.w_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        (SELECT MAX(i2.inv_quantity_on_hand)
         FROM inventory i2
         WHERE i2.inv_warehouse_sk = w.w_warehouse_sk) AS max_qty_warehouse
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_date_sk BETWEEN 2450800 AND 2450830
      AND w.w_county LIKE '%County'
      AND EXISTS (
          SELECT 1
          FROM inventory i3
          WHERE i3.inv_item_sk = i.inv_item_sk
            AND i3.inv_quantity_on_hand > 500
      )
    GROUP BY w.w_city, w.w_warehouse_sk
)
SELECT DISTINCT
    ci.w_city,
    ci.total_qty,
    'recent' AS period,
    ci.max_qty_warehouse
FROM recent_inventory ci
UNION ALL
SELECT DISTINCT
    oi.w_city,
    oi.total_qty,
    'older' AS period,
    oi.max_qty_warehouse
FROM older_inventory oi
ORDER BY w_city, period
LIMIT 100
