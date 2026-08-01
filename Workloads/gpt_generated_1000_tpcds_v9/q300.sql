SELECT
    d_sold.d_year AS sales_year,
    i.i_category AS item_category,
    i.i_class_id AS item_class_id,
    wsite.web_mkt_id AS market_id,
    cp.cp_department AS department,
    s.s_state AS store_state,
    SUM(ws.ws_net_paid_inc_ship) AS total_sales_inc_ship,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_profit) AS total_net_profit,
    CASE WHEN SUM(wr.wr_return_amt) > 0 THEN SUM(ws.ws_net_profit) - SUM(wr.wr_return_amt) ELSE SUM(ws.ws_net_profit) END AS net_profit_adj,
    (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_class_id = i.i_class_id) AS max_price_for_class,
    CASE WHEN AVG(ws.ws_sales_price) > (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_class_id = i.i_class_id) THEN 'Above Max' ELSE 'Within Range' END AS price_category,
    CASE WHEN SUM(ws.ws_quantity) > 1000 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001
  AND i.i_class_id IN (1, 5, 9)
  AND i.i_units = 'Carton'
  AND wsite.web_mkt_id = 3
  AND wsite.web_zip = '28579'
  AND cp.cp_department = 'Electronics'
  AND s.s_state = 'CA'
  AND r.r_reason_desc = 'Customer Not Satisfied'
GROUP BY
    d_sold.d_year,
    i.i_category,
    i.i_class_id,
    wsite.web_mkt_id,
    cp.cp_department,
    s.s_state
HAVING SUM(ws.ws_net_paid_inc_ship) > 1000
ORDER BY total_sales_inc_ship DESC
LIMIT 100
