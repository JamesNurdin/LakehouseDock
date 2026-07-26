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
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650
),
customer_mismatch_agg AS (
    SELECT
        c.c_customer_id,
        ca_bill.ca_city AS bill_city,
        ca_ship.ca_city AS ship_city,
        COUNT(m.ws_order_number) AS mismatched_order_cnt,
        MIN(m.ws_net_profit) AS min_net_profit,
        MAX(m.ws_net_profit) AS max_net_profit,
        AVG(m.ws_net_profit) AS avg_net_profit,
        SUM(m.ws_net_profit) AS total_net_profit
    FROM mismatched m
    JOIN customer c ON m.cust_sk = c.c_customer_sk
    LEFT JOIN customer_address ca_bill ON m.ws_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship ON m.ws_ship_addr_sk = ca_ship.ca_address_sk
    GROUP BY c.c_customer_id, ca_bill.ca_city, ca_ship.ca_city
)
SELECT
    cm.c_customer_id,
    cm.bill_city,
    cm.ship_city,
    cm.mismatched_order_cnt,
    cm.avg_net_profit,
    cm.total_net_profit,
    CASE 
        WHEN cm.total_net_profit > 30000 THEN 'Very High Profit Mismatch'
        WHEN cm.total_net_profit > 15000 THEN 'High Profit Mismatch'
        WHEN cm.total_net_profit > 5000 THEN 'Medium Profit Mismatch'
        ELSE 'Low Profit Mismatch'
    END AS profit_category,
    RANK() OVER (ORDER BY cm.total_net_profit DESC) AS profit_rank
FROM customer_mismatch_agg cm
ORDER BY profit_rank
LIMIT 5
