WITH mismatched AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_quantity
    FROM web_sales ws
    WHERE ws.ws_bill_addr_sk <> ws.ws_ship_addr_sk
      AND ws.ws_quantity > 5
),
customer_mismatch_agg AS (
    SELECT
        c.c_customer_id,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        COUNT(*) AS mismatched_order_cnt,
        SUM(ws_quantity) AS total_quantity,
        AVG(m.ws_net_profit) AS avg_net_profit,
        SUM(m.ws_net_profit) AS total_net_profit
    FROM mismatched m
    JOIN customer c ON m.cust_sk = c.c_customer_sk
    LEFT JOIN customer_address ca_bill ON m.ws_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship ON m.ws_ship_addr_sk = ca_ship.ca_address_sk
    GROUP BY c.c_customer_id, ca_bill.ca_state, ca_ship.ca_state
)
SELECT
    cma.c_customer_id,
    cma.bill_state,
    cma.ship_state,
    cma.mismatched_order_cnt,
    cma.total_quantity,
    cma.avg_net_profit,
    cma.total_net_profit,
    NTILE(4) OVER (ORDER BY cma.total_net_profit DESC) AS profit_quartile
FROM customer_mismatch_agg cma
WHERE cma.total_quantity > 20
ORDER BY profit_quartile, cma.total_net_profit DESC
