WITH
inventory_agg AS (
   SELECT
       inv_warehouse_sk,
       inv_date_sk,
       SUM(inv_quantity_on_hand) AS total_qty_on_hand
   FROM inventory
   WHERE inv_quantity_on_hand > 500
   GROUP BY inv_warehouse_sk, inv_date_sk
   HAVING SUM(inv_quantity_on_hand) > 1000
),
orders_diff AS (
   SELECT ws_order_number
   FROM web_sales
   EXCEPT
   SELECT cs_order_number
   FROM catalog_sales
)
SELECT
   ws.ws_order_number,
   d.d_date,
   d.d_year,
   w.w_warehouse_name,
   sm.sm_type,
   SUM(ws.ws_net_paid) AS total_net_paid,
   COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_sold,
   AVG(cs.cs_ext_ship_cost) AS avg_catalog_ship_cost,
   MIN(ws.ws_net_paid) AS min_net_paid,
   MAX(ws.ws_net_paid) AS max_net_paid,
   (SELECT SUM(total_qty_on_hand) FROM inventory_agg) AS overall_inventory_qty
FROM web_sales ws
JOIN orders_diff od ON ws.ws_order_number = od.ws_order_number
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN catalog_sales cs ON cs.cs_order_number = ws.ws_order_number
JOIN inventory_agg ia ON ia.inv_warehouse_sk = w.w_warehouse_sk AND ia.inv_date_sk = d.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
                AND ss.ss_hdemo_sk = hd.hd_demo_sk
                AND ss.ss_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2001
  AND w.w_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND r.r_reason_desc = 'Damaged'
  AND ws.ws_item_sk IN (SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 2000)
GROUP BY ws.ws_order_number, d.d_date, d.d_year, w.w_warehouse_name, sm.sm_type
HAVING SUM(ws.ws_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
