WITH recent_inventory AS (
   SELECT inv.inv_item_sk,
          inv.inv_warehouse_sk,
          inv.inv_date_sk,
          inv.inv_quantity_on_hand,
          d.d_date,
          i.i_product_name,
          i.i_current_price,
          w.w_warehouse_name
   FROM inventory inv
   JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
   JOIN item i ON inv.inv_item_sk = i.i_item_sk
   JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_current_year = 'Y'
     AND d.d_current_week = 'N'
     AND w.w_county = 'Richland County'
),
eligible_items AS (
   SELECT inv_item_sk
   FROM recent_inventory
   WHERE inv_quantity_on_hand > 100
   INTERSECT
   SELECT i_item_sk
   FROM item
   WHERE i_current_price > 50
),
full_calendar_warehouse AS (
   SELECT w.w_warehouse_sk,
          w.w_warehouse_name,
          d.d_date_sk,
          d.d_date
   FROM warehouse w
   FULL OUTER JOIN date_dim d ON FALSE
)
SELECT
   ROW_NUMBER() OVER (ORDER BY COALESCE(fcw.w_warehouse_name, 'ZZZ'), fcw.d_date) AS row_num,
   fcw.w_warehouse_sk,
   fcw.w_warehouse_name,
   fcw.d_date_sk,
   fcw.d_date,
   COALESCE(ri.total_qty, 0) AS total_quantity_on_hand,
   CASE WHEN EXISTS (
        SELECT 1
        FROM recent_inventory ri2
        WHERE ri2.inv_warehouse_sk = fcw.w_warehouse_sk
          AND ri2.inv_date_sk = fcw.d_date_sk
          AND ri2.inv_item_sk IN (SELECT inv_item_sk FROM eligible_items)
        ) THEN 'YES' ELSE 'NO' END AS has_eligible_item
FROM full_calendar_warehouse fcw
LEFT JOIN (
   SELECT inv_warehouse_sk,
          inv_date_sk,
          SUM(inv_quantity_on_hand) AS total_qty
   FROM recent_inventory
   WHERE inv_item_sk IN (SELECT inv_item_sk FROM eligible_items)
   GROUP BY inv_warehouse_sk, inv_date_sk
) ri
  ON ri.inv_warehouse_sk = fcw.w_warehouse_sk
 AND ri.inv_date_sk = fcw.d_date_sk
ORDER BY row_num
LIMIT 100
