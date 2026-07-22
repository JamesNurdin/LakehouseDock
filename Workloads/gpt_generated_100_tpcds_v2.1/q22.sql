SELECT
    w.w_warehouse_name,
    i.i_brand,
    i.i_category,
    td.t_hour,
    COUNT(*) AS order_count,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MIN(ws.ws_sales_price) AS min_sales_price,
    MAX(ws.ws_sales_price) AS max_sales_price
FROM web_sales ws
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer c_page ON wp.wp_customer_sk = c_page.c_customer_sk
WHERE ws.ws_sales_price > 20.00
  AND ws.ws_quantity BETWEEN 2 AND 5
  AND i.i_brand_id = 5
  AND w.w_county = 'Ziebach County'
  AND c_bill.c_email_address LIKE '%@N3rp.org'
  AND td.t_hour BETWEEN 9 AND 11
GROUP BY
    w.w_warehouse_name,
    i.i_brand,
    i.i_category,
    td.t_hour
ORDER BY total_net_paid DESC
LIMIT 100
