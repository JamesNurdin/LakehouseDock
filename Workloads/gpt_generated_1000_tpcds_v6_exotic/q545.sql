SELECT DISTINCT wp.wp_url, ws.ws_sales_price, ws.ws_net_profit
FROM tpcds.web_sales ws
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE ws.ws_sales_price > 50
  AND wp.wp_autogen_flag = 'Y'
