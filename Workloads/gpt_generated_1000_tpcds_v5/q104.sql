SELECT
    ws.ws_order_number,
    ws.ws_net_paid,
    wp.wp_url,
    wp.wp_type
FROM tpcds.web_sales ws
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_max_ad_count = 0
  AND ws.ws_bill_cdemo_sk = 436090
LIMIT 100
