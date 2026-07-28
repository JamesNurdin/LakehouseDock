SELECT
    ws.ws_order_number,
    ws.ws_sales_price,
    wp.wp_url,
    wp.wp_char_count
FROM tpcds.web_sales ws
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_char_count > 1000
  AND ws.ws_sales_price > 20.00
  AND wp.wp_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
ORDER BY ws.ws_sales_price DESC
LIMIT 100
