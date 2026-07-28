WITH sr AS (
    SELECT *
    FROM store_returns
    WHERE sr_return_amt_inc_tax > 1000
),
ws AS (
    SELECT *
    FROM web_sales
    WHERE ws_ext_sales_price > 500
)
SELECT DISTINCT
    cust_ret.c_customer_id         AS return_customer_id,
    cust_ship.c_customer_id        AS ship_customer_id,
    wp.wp_url,
    tr.t_hour                      AS return_hour,
    ws_time.t_hour                 AS sale_hour,
    wh.w_warehouse_name,
    SUM(sr.sr_net_loss)           AS total_return_loss,
    SUM(ws.ws_net_profit)         AS total_sales_profit,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns,
    COUNT(DISTINCT ws.ws_order_number)  AS distinct_orders
FROM sr
JOIN time_dim tr
  ON sr.sr_return_time_sk = tr.t_time_sk
JOIN customer cust_ret
  ON sr.sr_customer_sk = cust_ret.c_customer_sk
JOIN customer_address addr_ret
  ON sr.sr_addr_sk = addr_ret.ca_address_sk
JOIN customer_address addr_current
  ON cust_ret.c_current_addr_sk = addr_current.ca_address_sk
JOIN web_sales ws
  ON ws.ws_bill_customer_sk = cust_ret.c_customer_sk
JOIN time_dim ws_time
  ON ws.ws_sold_time_sk = ws_time.t_time_sk
JOIN customer cust_ship
  ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk
JOIN customer_address addr_bill
  ON ws.ws_bill_addr_sk = addr_bill.ca_address_sk
JOIN customer_address addr_ship
  ON ws.ws_ship_addr_sk = addr_ship.ca_address_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer cust_wp
  ON wp.wp_customer_sk = cust_wp.c_customer_sk
JOIN warehouse wh
  ON ws.ws_warehouse_sk = wh.w_warehouse_sk
WHERE wh.w_country = 'United States'
  AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_web_page_sk = wp.wp_web_page_sk
          AND wp2.wp_type = 'content'
    )
GROUP BY
    cust_ret.c_customer_id,
    cust_ship.c_customer_id,
    wp.wp_url,
    tr.t_hour,
    ws_time.t_hour,
    wh.w_warehouse_name
LIMIT 100
