SELECT
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_list_price,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    wp.wp_url,
    wp.wp_type,
    (ws.ws_quantity * ws.ws_list_price) AS total_list_price,
    (ws.ws_ext_sales_price - ws.ws_ext_discount_amt) AS net_sales_price,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
    CASE wp.wp_type
        WHEN 'Home' THEN 'Home Page'
        WHEN 'Product' THEN 'Product Page'
        ELSE 'Other'
    END AS page_category
FROM web_sales ws
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE ws.ws_sold_date_sk = 2451326
  AND wp.wp_type = 'dynamic                                           '
