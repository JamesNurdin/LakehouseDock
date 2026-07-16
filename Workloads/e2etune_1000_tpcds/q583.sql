WITH sales_agg AS (
  SELECT
    ca_bill.ca_state AS bill_state,
    ca_bill.ca_zip AS bill_zip,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(CASE WHEN ca_bill.ca_state <> ca_ship.ca_state THEN 1 ELSE 0 END) AS cross_state_shipments
  FROM web_sales ws
  JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2451000
    AND wp.wp_type = 'product'
    AND ca_bill.ca_location_type = 'single family'
  GROUP BY ca_bill.ca_state, ca_bill.ca_zip, wp.wp_type
  HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT
  bill_state,
  bill_zip,
  wp_type,
  orders,
  total_net_profit,
  total_sales,
  avg_quantity,
  cross_state_shipments,
  RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 10
