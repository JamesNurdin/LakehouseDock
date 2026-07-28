WITH inv_src AS (
   SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
   FROM inventory
),
inv_dst AS (
   SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
   FROM inventory
)
SELECT
   s.s_store_name,
   sm.sm_ship_mode_id,
   w.w_warehouse_name,
   i.i_category,
   SUM(ws.ws_ext_sales_price) AS total_web_sales,
   SUM(ss.ss_ext_sales_price) AS total_store_sales,
   COUNT(DISTINCT ws.ws_order_number) AS web_orders,
   AVG(p.p_cost) AS avg_promo_cost,
   ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS store_sales_rank
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN inv_src
  ON ss.ss_item_sk = inv_src.inv_item_sk
JOIN warehouse w
  ON inv_src.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
JOIN inv_dst
  ON ws.ws_item_sk = inv_dst.inv_item_sk
   AND inv_dst.inv_warehouse_sk <> inv_src.inv_warehouse_sk
WHERE EXISTS (
   SELECT 1 FROM promotion p2
   WHERE p2.p_promo_sk = ss.ss_promo_sk
     AND p2.p_discount_active = 'Y'
)
  AND we.web_zip = '41933'
GROUP BY
   s.s_store_name,
   sm.sm_ship_mode_id,
   w.w_warehouse_name,
   i.i_category
ORDER BY total_web_sales DESC
LIMIT 100
