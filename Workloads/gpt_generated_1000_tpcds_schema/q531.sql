SELECT
  ws.ws_order_number,
  ws.ws_net_paid,
  ws.ws_quantity,
  ws.ws_coupon_amt,
  site.web_name,
  site.web_city,
  site.web_state
FROM tpcds.web_sales ws
JOIN tpcds.web_site site
  ON ws.ws_web_site_sk = site.web_site_sk
WHERE ws.ws_coupon_amt > 1000
  AND ws.ws_quantity >= 15
  AND site.web_state = 'CA'
ORDER BY ws.ws_net_paid DESC
LIMIT 20
