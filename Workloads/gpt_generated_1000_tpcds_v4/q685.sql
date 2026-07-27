WITH filtered_inventory AS (
   SELECT i.inv_item_sk,
          i.inv_warehouse_sk,
          i.inv_quantity_on_hand,
          d.d_weekend
   FROM inventory i
   JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
   WHERE d.d_fy_week_seq BETWEEN 10 AND 13
     AND d.d_current_year = 'Y'
)
SELECT item_sk,
       weekend_flag,
       total_qty
FROM (
   SELECT inv_item_sk AS item_sk,
          'Weekend' AS weekend_flag,
          SUM(inv_quantity_on_hand) AS total_qty
   FROM filtered_inventory
   WHERE d_weekend = 'Y'
     AND EXISTS (
         SELECT 1
         FROM inventory i2
         WHERE i2.inv_item_sk = filtered_inventory.inv_item_sk
           AND i2.inv_warehouse_sk = 10
     )
   GROUP BY inv_item_sk

   UNION ALL

   SELECT inv_item_sk AS item_sk,
          'Weekday' AS weekend_flag,
          SUM(inv_quantity_on_hand) AS total_qty
   FROM filtered_inventory
   WHERE d_weekend = 'N'
     AND inv_quantity_on_hand > (
         SELECT AVG(inv_quantity_on_hand) FROM filtered_inventory
     )
   GROUP BY inv_item_sk
) AS combined
ORDER BY total_qty DESC
LIMIT 100
