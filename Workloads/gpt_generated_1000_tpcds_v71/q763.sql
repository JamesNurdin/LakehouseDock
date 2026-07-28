SELECT
  ws_site.web_name,
  sm.sm_carrier,
  p.p_promo_name,
  SUM(ws.ws_net_paid) AS total_net_paid,
  AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
  COUNT(*) AS order_cnt,
  MIN(ws.ws_ext_ship_cost) AS min_ship_cost,
  MAX(ws.ws_ext_list_price) AS max_list_price
FROM web_sales ws
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE sm.sm_carrier = 'LATVIAN'
  AND sm.sm_contract = 'HVDFCcQ'
  AND ws.ws_ext_list_price > 5000
  AND ws.ws_coupon_amt < 500
  AND ws_site.web_zip = '78048'
GROUP BY ROLLUP (ws_site.web_name, sm.sm_carrier, p.p_promo_name)
ORDER BY total_net_paid DESC, ws_site.web_name
LIMIT 100
