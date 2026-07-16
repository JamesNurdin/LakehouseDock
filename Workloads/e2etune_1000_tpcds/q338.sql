WITH inv_agg AS (
    SELECT inv_warehouse_sk,
           inv_item_sk,
           DATE_FORMAT(date_add('day', inv_date_sk - 2451545, DATE '2000-01-01'), '%Y-%m-%d') AS inv_date,
           SUM(inv_quantity_on_hand) AS total_qty,
           AVG(inv_quantity_on_hand) AS avg_qty,
           MAX(inv_quantity_on_hand) AS max_qty,
           MIN(inv_quantity_on_hand) AS min_qty,
           COUNT(*) AS inv_rows
    FROM inventory
    WHERE inv_quantity_on_hand > 200
      AND inv_warehouse_sk IN (1, 9, 15)
    GROUP BY inv_warehouse_sk,
             inv_item_sk,
             DATE_FORMAT(date_add('day', inv_date_sk - 2451545, DATE '2000-01-01'), '%Y-%m-%d')
    HAVING SUM(inv_quantity_on_hand) > 500
)
SELECT a.inv_warehouse_sk,
       a.inv_item_sk,
       a.inv_date,
       a.total_qty,
       a.avg_qty,
       a.max_qty,
       a.min_qty,
       a.inv_rows,
       s.sm_carrier,
       s.sm_code,
       s.sm_type
FROM inv_agg a
JOIN ship_mode s
  ON a.inv_warehouse_sk = s.sm_ship_mode_sk
WHERE s.sm_carrier IN ('UPS', 'FEDEX')
ORDER BY a.total_qty DESC
LIMIT 100
