WITH expanded AS (
   SELECT i.inv_item_sk,
          w.w_warehouse_id,
          w.w_gmt_offset,
          w.w_county,
          qty_val,
          CASE WHEN qty_val > 500 THEN 'High' ELSE 'Low' END AS qty_category
   FROM inventory i
   JOIN warehouse w
     ON i.inv_warehouse_sk = w.w_warehouse_sk
   CROSS JOIN UNNEST(array[i.inv_quantity_on_hand, i.inv_quantity_on_hand + 1]) AS t(qty_val)
),
filtered_a AS (
   SELECT w_warehouse_id, inv_item_sk, qty_val, qty_category
   FROM expanded
   WHERE w_gmt_offset = -5.00
),
filtered_b AS (
   SELECT w_warehouse_id, inv_item_sk, qty_val, qty_category
   FROM expanded
   WHERE w_county = 'San Miguel County'
),
union_ab AS (
   SELECT w_warehouse_id, inv_item_sk, qty_val, qty_category
   FROM filtered_a
   UNION
   SELECT w_warehouse_id, inv_item_sk, qty_val, qty_category
   FROM filtered_b
),
all_items AS (
   SELECT inv_item_sk FROM inventory
),
low_items AS (
   SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand < 100
),
except_items AS (
   SELECT inv_item_sk FROM all_items
   EXCEPT
   SELECT inv_item_sk FROM low_items
),
high_items AS (
   SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 500
),
warehouse_subset AS (
   SELECT inv_item_sk FROM inventory WHERE inv_warehouse_sk IN (1, 4)
),
intersect_items AS (
   SELECT inv_item_sk FROM high_items
   INTERSECT
   SELECT inv_item_sk FROM warehouse_subset
)
SELECT ua.w_warehouse_id,
       ua.inv_item_sk,
       ua.qty_val,
       ua.qty_category
FROM union_ab ua
WHERE ua.inv_item_sk IN (SELECT inv_item_sk FROM except_items)
  AND ua.inv_item_sk IN (SELECT inv_item_sk FROM intersect_items)
ORDER BY ua.w_warehouse_id, ua.inv_item_sk
LIMIT 100
