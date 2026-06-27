WITH sales_by_addresses AS (
    SELECT
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    WHERE ca_bill.ca_country = 'United States'
      AND ca_ship.ca_country = 'United States'
    GROUP BY ca_bill.ca_state, ca_ship.ca_state
)
SELECT
    bill_state,
    ship_state,
    total_sales,
    total_profit,
    num_orders,
    avg_discount,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM sales_by_addresses
ORDER BY total_sales DESC
LIMIT 50
