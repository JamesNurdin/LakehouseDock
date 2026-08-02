WITH
  web_items AS (
    SELECT DISTINCT ws.ws_item_sk AS i_item_sk
    FROM web_sales ws
    JOIN time_dim td_w ON ws.ws_sold_time_sk = td_w.t_time_sk
    WHERE td_w.t_hour BETWEEN 9 AND 17
      AND ws.ws_net_paid > 1000
  ),
  store_items AS (
    SELECT DISTINCT ss.ss_item_sk AS i_item_sk
    FROM store_sales ss
    JOIN time_dim td_s ON ss.ss_sold_time_sk = td_s.t_time_sk
    WHERE td_s.t_hour BETWEEN 9 AND 17
      AND ss.ss_net_paid > 800
  ),
  common_items AS (
    SELECT i_item_sk FROM web_items
    INTERSECT
    SELECT i_item_sk FROM store_items
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  p.p_promo_name,
  w.w_warehouse_name,
  COUNT(DISTINCT cs.cs_order_number)          AS num_catalog_orders,
  SUM(cs.cs_net_paid)                         AS sum_catalog_sales,
  SUM(cr.cr_net_loss)                         AS sum_catalog_returns_loss,
  COUNT(DISTINCT ss.ss_ticket_number)         AS num_store_sales,
  SUM(ss.ss_net_paid)                         AS sum_store_sales,
  SUM(sr.sr_net_loss)                         AS sum_store_returns_loss,
  COUNT(DISTINCT ws.ws_order_number)          AS num_web_orders,
  SUM(ws.ws_net_paid)                         AS sum_web_sales,
  SUM(wr.wr_net_loss)                         AS sum_web_returns_loss,
  AVG(ws.ws_net_paid)                         AS avg_web_sales,
  MIN(ws.ws_net_paid)                         AS min_web_sales,
  MAX(ws.ws_net_paid)                         AS max_web_sales
FROM time_dim td
JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
  AND cr.cr_order_number = cs.cs_order_number
JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
  AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
  AND wr.wr_order_number = ws.ws_order_number
JOIN item i ON i.i_item_sk = cs.cs_item_sk
  AND ss.ss_item_sk = i.i_item_sk
  AND ws.ws_item_sk = i.i_item_sk
  AND cr.cr_item_sk = i.i_item_sk
  AND sr.sr_item_sk = i.i_item_sk
  AND wr.wr_item_sk = i.i_item_sk
JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk
  AND ss.ss_promo_sk = p.p_promo_sk
  AND ws.ws_promo_sk = p.p_promo_sk
JOIN customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
  AND c.c_customer_sk = cs.cs_ship_customer_sk
  AND c.c_customer_sk = ss.ss_customer_sk
  AND c.c_customer_sk = ws.ws_bill_customer_sk
  AND c.c_customer_sk = ws.ws_ship_customer_sk
JOIN customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
  AND ca.ca_address_sk = cs.cs_ship_addr_sk
  AND ca.ca_address_sk = ss.ss_addr_sk
  AND ca.ca_address_sk = ws.ws_bill_addr_sk
  AND ca.ca_address_sk = ws.ws_ship_addr_sk
JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
  AND w.w_warehouse_sk = ws.ws_warehouse_sk
  AND w.w_warehouse_sk = cr.cr_warehouse_sk
JOIN web_site wsit ON wsit.web_site_sk = ws.ws_web_site_sk
WHERE
  p.p_channel_catalog = 'N'
  AND p.p_channel_press = 'N'
  AND p.p_purpose = 'Unknown'
  AND c.c_birth_country = 'MONACO'
  AND w.w_state = 'CA'
  AND td.t_hour BETWEEN 9 AND 17
  AND cs.cs_quantity > 5
  AND ws.ws_quantity > 3
  AND i.i_item_sk IN (SELECT i_item_sk FROM common_items)
  AND EXISTS (
    SELECT 1 FROM inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk
      AND inv.inv_warehouse_sk = w.w_warehouse_sk
      AND inv.inv_quantity_on_hand > 0
  )
GROUP BY
  i.i_item_id,
  i.i_product_name,
  p.p_promo_name,
  w.w_warehouse_name
ORDER BY
  sum_catalog_sales DESC
LIMIT 100
