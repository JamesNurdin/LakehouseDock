WITH weekend_data AS (
   SELECT
       di.d_date AS record_date,
       di.d_date_sk AS date_sk,
       i.inv_warehouse_sk,
       SUM(i.inv_quantity_on_hand) AS total_qty,
       (SELECT max(inv_quantity_on_hand)
          FROM inventory i2
         WHERE i2.inv_date_sk = di.d_date_sk) AS max_qty_for_date
   FROM inventory i
   JOIN date_dim di ON i.inv_date_sk = di.d_date_sk
   WHERE di.d_weekend = 'Y'
     AND i.inv_quantity_on_hand > 500
   GROUP BY di.d_date, di.d_date_sk, i.inv_warehouse_sk
),
weekday_data AS (
   SELECT
       di.d_date AS record_date,
       di.d_date_sk AS date_sk,
       i.inv_warehouse_sk,
       SUM(i.inv_quantity_on_hand) AS total_qty,
       (SELECT max(inv_quantity_on_hand)
          FROM inventory i2
         WHERE i2.inv_date_sk = di.d_date_sk) AS max_qty_for_date
   FROM inventory i
   JOIN date_dim di ON i.inv_date_sk = di.d_date_sk
   WHERE di.d_weekend = 'N'
     AND i.inv_quantity_on_hand <= 200
     AND EXISTS (SELECT 1
                   FROM inventory i3
                  WHERE i3.inv_date_sk = di.d_date_sk
                    AND i3.inv_quantity_on_hand > 1000)
   GROUP BY di.d_date, di.d_date_sk, i.inv_warehouse_sk
),
combined AS (
   SELECT record_date,
          inv_warehouse_sk,
          total_qty,
          max_qty_for_date,
          'Weekend' AS segment
   FROM weekend_data
   UNION ALL
   SELECT record_date,
          inv_warehouse_sk,
          total_qty,
          max_qty_for_date,
          'Weekday' AS segment
   FROM weekday_data
)
SELECT
   c.record_date,
   c.inv_warehouse_sk,
   c.total_qty,
   c.max_qty_for_date,
   c.segment,
   ROW_NUMBER() OVER (PARTITION BY c.record_date ORDER BY c.total_qty DESC) AS warehouse_rank
FROM combined c
ORDER BY c.record_date DESC, c.total_qty DESC
LIMIT 100
