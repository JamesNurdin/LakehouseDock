SELECT
  w_cs.w_warehouse_id,
  w_cs.w_city,
  COUNT(DISTINCT c.c_customer_id) AS unique_customers,
  SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
  SUM(ws.ws_ext_sales_price) AS total_web_sales,
  SUM(sr.sr_return_amt) AS total_store_returns,
  SUM(wr.wr_return_amt) AS total_web_returns,
  (SUM(cs.cs_net_profit) - SUM(sr.sr_net_loss) - SUM(wr.wr_net_loss)) AS net_profit
FROM catalog_sales cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer cust_ship ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
-- Web sales linked through the same billing customer
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN customer cust_ws_ship ON ws.ws_ship_customer_sk = cust_ws_ship.c_customer_sk
JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN customer_demographics cd_ws_ship ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
-- Store returns linked through the same customer
JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
-- Web returns linked to web sales via order number
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN customer cust_wr_refund ON wr.wr_refunded_customer_sk = cust_wr_refund.c_customer_sk
JOIN customer_demographics cd_wr_refund ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
JOIN household_demographics hd_wr_refund ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
JOIN customer cust_wr_returning ON wr.wr_returning_customer_sk = cust_wr_returning.c_customer_sk
JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
WHERE EXISTS (
    SELECT 1
    FROM inventory i
    WHERE i.inv_warehouse_sk = w_cs.w_warehouse_sk
      AND i.inv_quantity_on_hand > 0
)
GROUP BY w_cs.w_warehouse_id, w_cs.w_city
HAVING (SUM(cs.cs_net_profit) - SUM(sr.sr_net_loss) - SUM(wr.wr_net_loss)) > 1000
ORDER BY net_profit DESC
LIMIT 100
