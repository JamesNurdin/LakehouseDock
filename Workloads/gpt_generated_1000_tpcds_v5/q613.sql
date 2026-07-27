WITH filtered_inventory AS (
   SELECT inv_warehouse_sk, inv_item_sk, inv_quantity_on_hand, inv_date_sk
   FROM inventory
   WHERE inv_quantity_on_hand > 700
     AND inv_date_sk = 2450843
)
SELECT
   w.w_city,
   w.w_state,
   fi.inv_item_sk,
   SUM(ws.ws_net_paid) AS total_net_paid,
   AVG(ws.ws_ext_tax) AS avg_ext_tax,
   COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
   MIN(fi.inv_quantity_on_hand) AS min_qty_on_hand,
   MAX(fi.inv_quantity_on_hand) AS max_qty_on_hand
FROM filtered_inventory fi
JOIN warehouse w
   ON fi.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
   ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE w.w_zip = '46098'
  AND w.w_suite_number = 'Suite Q'
  AND ws.ws_ext_tax > 100
  AND ws.ws_ship_cdemo_sk IN (1543645, 375076)
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk
          AND ws2.ws_quantity > 5
        LIMIT 1
      )
GROUP BY GROUPING SETS (
   (w.w_city, w.w_state, fi.inv_item_sk),
   (w.w_city, w.w_state),
   (w.w_city),
   ()
)
ORDER BY total_net_paid DESC
LIMIT 100
