SELECT
  ws.ws_order_number,
  ws.ws_net_paid,
  ws.ws_coupon_amt,
  w.web_name
FROM
  web_sales ws
JOIN
  web_site w
  ON ws.ws_web_site_sk = w.web_site_sk
WHERE
  w.web_site_id = 'AAAAAAAAPBAAAAAA'
  AND ws.ws_coupon_amt > 1000.00
ORDER BY
  ws.ws_net_paid DESC
LIMIT 10
