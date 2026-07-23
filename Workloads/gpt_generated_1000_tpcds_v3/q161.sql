SELECT
  c.c_birth_country,
  cc.cc_state,
  s.s_state,
  w.w_state,
  COUNT(DISTINCT ws.ws_order_number) AS order_count,
  SUM(ws.ws_net_paid) AS total_sales,
  SUM(ws.ws_net_profit) AS total_profit,
  SUM(cr.cr_return_amount) AS total_catalog_return_amount,
  SUM(sr.sr_net_loss) AS total_store_return_loss,
  SUM(wr.wr_net_loss) AS total_web_return_loss,
  AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty_on_hand
FROM
  tpcds.customer c
  JOIN tpcds.customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  JOIN tpcds.store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
  JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
  JOIN tpcds.web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN tpcds.web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE
  c.c_birth_country IN ('JAPAN', 'BAHAMAS')
  AND c.c_birth_day = 13
  AND cc.cc_city = 'Seattle'
  AND cp.cp_type = 'Electronics'
  AND w.w_state = 'CA'
  AND s.s_state = 'TX'
GROUP BY
  c.c_birth_country,
  cc.cc_state,
  s.s_state,
  w.w_state
ORDER BY
  total_sales DESC
LIMIT 100
