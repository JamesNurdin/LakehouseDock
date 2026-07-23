SELECT
    wp.wp_web_page_id,
    wp.wp_type,
    wp.wp_image_count,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS avg_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    MIN(ws.ws_ext_ship_cost) AS min_ship_cost,
    MAX(ws.ws_ext_ship_cost) AS max_ship_cost,
    SUM(ws.ws_quantity) AS total_quantity
FROM tpcds.web_sales ws
INNER JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_rec_end_date = DATE '2001-09-02'
  AND wp.wp_image_count >= 5
  AND wp.wp_web_page_id LIKE 'AAAAAAA%'
  AND ws.ws_ship_date_sk IN (2452240, 2452280)
  AND ws.ws_ext_ship_cost > 100.00
  AND ws.ws_bill_hdemo_sk = 351
GROUP BY wp.wp_web_page_id, wp.wp_type, wp.wp_image_count
ORDER BY total_sales DESC
LIMIT 100
