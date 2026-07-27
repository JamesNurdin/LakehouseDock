SELECT DISTINCT ws.ws_order_number,
                ws.ws_net_paid,
                ws.ws_ext_ship_cost,
                ws.ws_list_price
FROM tpcds.web_sales ws
JOIN tpcds.web_site w
  ON ws.ws_web_site_sk = w.web_site_sk
WHERE w.web_zip = '48059'
  AND ws.ws_list_price > 100.00
