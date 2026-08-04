WITH inv_agg AS (
   SELECT
       inv_warehouse_sk,
       COUNT(*) AS item_count,
       SUM(inv_quantity_on_hand) AS total_qty,
       AVG(inv_quantity_on_hand) AS avg_qty,
       MIN(inv_quantity_on_hand) AS min_qty,
       MAX(inv_quantity_on_hand) AS max_qty
   FROM inventory
   WHERE inv_item_sk IN (101428, 101431, 101419, 101438, 101432)
     AND inv_quantity_on_hand > 200
     AND inv_quantity_on_hand < 1000
     AND inv_warehouse_sk IN (1, 2, 3, 5, 17)
     AND inv_item_sk <> 0
   GROUP BY inv_warehouse_sk
),

union_set AS (
   SELECT
       w.w_warehouse_id,
       w.w_city,
       w.w_state,
       i.item_count,
       i.total_qty,
       ws.suite_len
   FROM inv_agg i
   FULL OUTER JOIN warehouse w
     ON i.inv_warehouse_sk = w.w_warehouse_sk
   CROSS JOIN LATERAL (
       SELECT length(w.w_suite_number) AS suite_len
   ) ws
   WHERE EXISTS (
       SELECT 1 FROM inventory inv2
       WHERE inv2.inv_warehouse_sk = w.w_warehouse_sk
         AND inv2.inv_quantity_on_hand > 600
   )
     AND w.w_state = 'CA'
     AND w.w_city LIKE 'San%'
     AND w.w_warehouse_sq_ft > 12000
     AND w.w_gmt_offset BETWEEN -5.00 AND -4.00
     AND w.w_country = 'United States'

   UNION DISTINCT

   SELECT
       w.w_warehouse_id,
       w.w_city,
       w.w_state,
       i.item_count,
       i.total_qty,
       ws.suite_len
   FROM inv_agg i
   FULL OUTER JOIN warehouse w
     ON i.inv_warehouse_sk = w.w_warehouse_sk
   CROSS JOIN LATERAL (
       SELECT length(w.w_suite_number) AS suite_len
   ) ws
   WHERE EXISTS (
       SELECT 1 FROM inventory inv2
       WHERE inv2.inv_warehouse_sk = w.w_warehouse_sk
         AND inv2.inv_quantity_on_hand BETWEEN 400 AND 800
   )
     AND w.w_state = 'TX'
     AND w.w_city LIKE 'Houston%'
     AND w.w_warehouse_sq_ft BETWEEN 8000 AND 25000
     AND w.w_gmt_offset = -6.00
     AND w.w_country = 'United States'
)

SELECT
   w_warehouse_id,
   w_city,
   w_state,
   SUM(item_count) AS total_items,
   SUM(total_qty) AS total_quantity,
   AVG(suite_len) AS avg_suite_len,
   MIN(total_qty) AS min_quantity,
   MAX(total_qty) AS max_quantity
FROM union_set
GROUP BY w_warehouse_id, w_city, w_state
ORDER BY total_quantity DESC
OFFSET 0
LIMIT 100
