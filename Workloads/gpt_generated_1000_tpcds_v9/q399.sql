SELECT
  cs.cs_order_number,
  cc.cc_call_center_id,
  p.p_promo_id,
  sm.sm_type,
  w.w_warehouse_name,
  ca_bill.ca_city AS bill_city,
  ca_ship.ca_city AS ship_city,
  cs.cs_quantity,
  cs.cs_net_paid,
  cs.cs_net_profit,
  ws.ws_quantity,
  ws.ws_net_paid,
  ws.ws_net_profit,
  cr.cr_return_quantity,
  cr.cr_return_amount,
  sr.sr_return_quantity,
  sr.sr_return_amt,
  CASE WHEN sr.sr_return_quantity IS NULL THEN 'No Return' ELSE 'Returned' END AS store_return_status,
  RANK() OVER (PARTITION BY p.p_promo_id ORDER BY cs.cs_net_profit DESC) AS promo_net_profit_rank,
  ROW_NUMBER() OVER (ORDER BY (cs.cs_net_paid + COALESCE(ws.ws_net_paid, 0)) DESC) AS overall_sales_rank
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN store_returns sr ON sr.sr_addr_sk = ca_bill.ca_address_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
JOIN customer_address ca_cr_refunded ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
JOIN customer_address ca_cr_returning ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk
JOIN web_sales ws ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
    AND ws.ws_promo_sk = p.p_promo_sk
JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
WHERE
    cc.cc_division_name = 'able'
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
    AND w.w_city = 'Los Angeles'
    AND cs.cs_quantity > 5
    AND cs.cs_net_paid > 1000
    AND cr.cr_return_quantity > 0
    AND ws.ws_quantity > 2
LIMIT 100
