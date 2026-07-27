SELECT
    ws.ws_order_number,
    ws.ws_net_paid,
    ws.ws_coupon_amt,
    site.web_name,
    site.web_city
FROM tpcds.web_sales ws
JOIN tpcds.web_site site
  ON ws.ws_web_site_sk = site.web_site_sk
WHERE ws.ws_ship_hdemo_sk = 5032
  AND site.web_country = 'United States'
ORDER BY ws.ws_net_paid DESC
LIMIT 100
