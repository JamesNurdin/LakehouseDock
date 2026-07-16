SELECT
    ca_bill.ca_state AS billing_state,
    ca_ship.ca_state AS shipping_state,
    wp.wp_type AS page_type,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_quantity) AS avg_quantity,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
    COUNT(*) AS order_count
FROM web_sales ws
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE ca_bill.ca_city IN ('Fairfield', 'Fairview')
  AND ca_ship.ca_city IN ('Oak Ridge', 'Glendale')
  AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
GROUP BY ROLLUP(ca_bill.ca_state, ca_ship.ca_state, wp.wp_type)
ORDER BY total_profit DESC
LIMIT 100
