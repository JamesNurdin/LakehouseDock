WITH
  item_sales AS (
    SELECT
      i.i_item_sk,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_quantity) AS total_qty
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
  ),
  latest_inventory AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_warehouse_sk,
      MAX(inv.inv_date_sk) AS latest_date_sk,
      SUM(inv.inv_quantity_on_hand) AS qty_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  i.i_category,
  s.s_store_id,
  s.s_store_name,
  cc.cc_name AS call_center_name,
  cp.cp_catalog_number,
  r.r_reason_desc,
  COALESCE(isales.total_sales, 0) AS total_sales,
  COALESCE(isales.total_qty, 0) AS total_qty,
  COALESCE(li.qty_on_hand, 0) AS inventory_on_hand,
  COUNT(DISTINCT ws.ws_order_number) AS web_orders,
  SUM(CASE WHEN ws.ws_net_profit IS NOT NULL THEN ws.ws_net_profit ELSE 0 END) AS web_net_profit,
  SUM(CASE WHEN sr.sr_net_loss IS NOT NULL THEN sr.sr_net_loss ELSE 0 END) AS store_net_loss,
  SUM(CASE WHEN cr.cr_net_loss IS NOT NULL THEN cr.cr_net_loss ELSE 0 END) AS catalog_net_loss,
  SUM(CASE WHEN wr.wr_net_loss IS NOT NULL THEN wr.wr_net_loss ELSE 0 END) AS web_return_net_loss
FROM item i
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN latest_inventory li ON li.inv_item_sk = i.i_item_sk AND li.inv_warehouse_sk = inv.inv_warehouse_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN item_sales isales ON isales.i_item_sk = i.i_item_sk
WHERE td.t_hour BETWEEN 9 AND 17
  AND s.s_state = 'CA'
  AND w.w_state = 'CA'
GROUP BY
  i.i_item_id,
  i.i_product_name,
  i.i_category,
  s.s_store_id,
  s.s_store_name,
  cc.cc_name,
  cp.cp_catalog_number,
  r.r_reason_desc,
  isales.total_sales,
  isales.total_qty,
  li.qty_on_hand
ORDER BY total_sales DESC
LIMIT 100
