SELECT
    cc.cc_name,
    smc.sm_carrier AS cs_ship_carrier,
    i_cat.i_category,
    ca_bill.ca_state AS cs_bill_state,
    ca_ship.ca_state AS cs_ship_state,
    sm_web.sm_carrier AS ws_ship_carrier,
    ca_ws_bill.ca_state AS ws_bill_state,
    ca_ws_ship.ca_state AS ws_ship_state,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_cs_net_paid,
    SUM(ws.ws_net_paid_inc_ship_tax) AS total_ws_net_paid,
    COUNT(*) AS order_cnt
FROM tpcds.catalog_sales cs
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.ship_mode smc
  ON cs.cs_ship_mode_sk = smc.sm_ship_mode_sk
JOIN tpcds.item i_cat
  ON cs.cs_item_sk = i_cat.i_item_sk
JOIN tpcds.customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN tpcds.web_sales ws
  ON ws.ws_item_sk = i_cat.i_item_sk
JOIN tpcds.ship_mode sm_web
  ON ws.ws_ship_mode_sk = sm_web.sm_ship_mode_sk
JOIN tpcds.customer_address ca_ws_bill
  ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN tpcds.customer_address ca_ws_ship
  ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
WHERE cs.cs_wholesale_cost > 20
  AND smc.sm_carrier = 'UPS'
  AND ca_bill.ca_gmt_offset = -5.00
  AND ws.ws_ext_discount_amt > 0
GROUP BY
    cc.cc_name,
    smc.sm_carrier,
    i_cat.i_category,
    ca_bill.ca_state,
    ca_ship.ca_state,
    sm_web.sm_carrier,
    ca_ws_bill.ca_state,
    ca_ws_ship.ca_state
ORDER BY total_ws_net_paid DESC
LIMIT 100
