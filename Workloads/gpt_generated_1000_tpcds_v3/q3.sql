WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 0
      AND inv_date_sk >= 2450900
      AND inv_date_sk <= 2451100
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    i.i_category,
    w.w_city,
    SUM(inv_agg.total_qty) AS category_city_qty,
    AVG(inv_agg.total_qty) AS avg_qty_per_item,
    CASE WHEN SUM(inv_agg.total_qty) > 5000 THEN 'High' ELSE 'Low' END AS qty_level,
    (SELECT AVG(total_qty) FROM inv_agg) AS overall_avg_qty
FROM inv_agg
JOIN item i ON inv_agg.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.i_category_id = 5
  AND i.i_current_price > 20
  AND w.w_warehouse_sq_ft > 500000
  AND EXISTS (
        SELECT 1
        FROM inventory i2
        WHERE i2.inv_item_sk = i.i_item_sk
          AND i2.inv_quantity_on_hand > 1000
    )
GROUP BY i.i_category, w.w_city
ORDER BY category_city_qty DESC
LIMIT 100
