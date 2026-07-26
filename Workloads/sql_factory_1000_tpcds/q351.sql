WITH mismatched AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_sold_date_sk
    FROM web_sales ws
    WHERE ws.ws_bill_addr_sk <> ws.ws_ship_addr_sk
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
),
customer_mismatch_agg AS (
    SELECT
        c.c_customer_id,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        COUNT(m.ws_order_number) AS mismatched_order_cnt,
        SUM(m.ws_net_profit) AS total_net_profit,
        MIN(m.ws_net_profit) AS min_net_profit,
        MAX(m.ws_net_profit) AS max_net_profit
    FROM mismatched m
    JOIN customer c ON m.cust_sk = c.c_customer_sk
    LEFT JOIN customer_address ca_bill ON m.ws_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship ON m.ws_ship_addr_sk = ca_ship.ca_address_sk
    GROUP BY c.c_customer_id, ca_bill.ca_state, ca_ship.ca_state
)
SELECT
    cm.c_customer_id,
    cm.bill_state,
    cm.ship_state,
    cm.mismatched_order_cnt,
    cm.total_net_profit,
    cm.min_net_profit,
    cm.max_net_profit,
    CASE 
        WHEN cm.total_net_profit > 30000 THEN 'Very High Profit Mismatch'
        WHEN cm.total_net_profit > 10000 THEN 'High Profit Mismatch'
        ELSE 'Moderate Profit Mismatch'
    END AS profit_category,
    ROW_NUMBER() OVER (ORDER BY cm.total_net_profit DESC) AS profit_rank
FROM customer_mismatch_agg cm
ORDER BY profit_rank
LIMIT 5
