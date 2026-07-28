SELECT
    i.i_category AS item_category,
    ca.ca_state AS customer_state,
    w_cr.w_state AS warehouse_state,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(i.i_current_price) AS avg_item_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
    MIN(ss.ss_sales_price) AS min_sales_price,
    MAX(ss.ss_sales_price) AS max_sales_price
FROM store_sales ss
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN catalog_returns cr
  ON i.i_item_sk = cr.cr_item_sk
LEFT JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN ship_mode sm_cr
  ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
LEFT JOIN warehouse w_cr
  ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
LEFT JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN inventory inv
  ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN warehouse w_inv
  ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
LEFT JOIN web_sales ws
  ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
LEFT JOIN ship_mode sm_ws
  ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
LEFT JOIN warehouse w_ws
  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
WHERE ss.ss_quantity BETWEEN 1 AND 10
  AND i.i_current_price > 50
  AND ca.ca_state = 'CA'
  AND cd.cd_gender = 'F'
  AND ws.ws_sales_price > 200
GROUP BY
    i.i_category,
    ca.ca_state,
    w_cr.w_state
HAVING SUM(ss.ss_ext_sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 100
