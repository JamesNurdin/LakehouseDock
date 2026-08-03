WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_web_page_sk
    FROM web_sales ws
    WHERE ws.ws_order_number IN (
        SELECT ws1.ws_order_number FROM web_sales ws1 WHERE ws1.ws_net_profit > 0
        INTERSECT
        SELECT ws2.ws_order_number FROM web_sales ws2 WHERE ws2.ws_quantity > 5
    )
    AND ws.ws_order_number NOT IN (SELECT sr_ticket_number FROM store_returns)
)
SELECT
    w.w_warehouse_name,
    ws_site.web_name,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    wp.wp_type,
    COUNT(DISTINCT base.ws_order_number) AS order_cnt,
    SUM(base.ws_net_profit) AS total_net_profit,
    SUM(l_ret.total_return_amt) AS total_return_amount,
    SUM(l_ret.total_return_tax) AS total_return_tax
FROM filtered_sales base
JOIN warehouse w ON base.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws_site ON base.ws_web_site_sk = ws_site.web_site_sk
JOIN web_page wp ON base.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer_address ca_bill ON base.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON base.ws_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN store_returns sr ON sr.sr_addr_sk = ca_bill.ca_address_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = base.ws_order_number
LEFT JOIN customer_address ca_refund ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
LEFT JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
LEFT JOIN web_page wp_ret ON wr.wr_web_page_sk = wp_ret.wp_web_page_sk
CROSS JOIN LATERAL (
    SELECT
        COALESCE(SUM(wr2.wr_return_amt), 0) AS total_return_amt,
        COALESCE(SUM(wr2.wr_return_tax), 0) AS total_return_tax
    FROM web_returns wr2
    WHERE wr2.wr_order_number = base.ws_order_number
      AND wr2.wr_returning_addr_sk = ca_ship.ca_address_sk
) AS l_ret
GROUP BY
    w.w_warehouse_name,
    ws_site.web_name,
    ca_bill.ca_state,
    ca_ship.ca_state,
    wp.wp_type
ORDER BY total_net_profit DESC
LIMIT 100
