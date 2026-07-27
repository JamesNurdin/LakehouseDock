WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_class_id,
        i.i_units,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        AVG(ws.ws_wholesale_cost) AS avg_wholesale_cost
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_wholesale_cost > 50
      AND ws.ws_ship_mode_sk IN (1, 7)
      AND i.i_units IN ('Pound', 'Case')
      AND i.i_class_id BETWEEN 2 AND 6
    GROUP BY i.i_item_sk, i.i_class_id, i.i_units
),
inventory_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand,
        MAX(inv_quantity_on_hand) AS max_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 500
      AND inv_date_sk BETWEEN 2450800 AND 2451100
    GROUP BY inv_item_sk
)
SELECT
    isales.i_class_id,
    isales.i_units,
    SUM(isales.total_sales) AS class_units_sales,
    AVG(isales.total_profit) AS avg_profit_per_item,
    SUM(isales.total_sales) / NULLIF(SUM(isales.sales_cnt), 0) AS avg_sale_per_transaction,
    COUNT(DISTINCT isales.i_item_sk) AS distinct_items,
    (
        SELECT MAX(max_on_hand)
        FROM inventory_agg ia2
        WHERE ia2.inv_item_sk = isales.i_item_sk
    ) AS item_max_inventory
FROM item_sales isales
JOIN inventory_agg iagg ON isales.i_item_sk = iagg.inv_item_sk
WHERE iagg.total_on_hand > 1000
  AND EXISTS (
      SELECT 1
      FROM inventory inv
      WHERE inv.inv_item_sk = isales.i_item_sk
        AND inv.inv_quantity_on_hand = iagg.max_on_hand
        AND inv.inv_date_sk = 2451081
  )
GROUP BY isales.i_class_id, isales.i_units, isales.i_item_sk
HAVING SUM(isales.total_sales) > 10000
ORDER BY class_units_sales DESC
LIMIT 100
