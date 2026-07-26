WITH mismatched AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_paid
    FROM web_sales ws
    WHERE ws.ws_bill_addr_sk <> ws.ws_ship_addr_sk
      AND ws.ws_net_paid BETWEEN 0 AND 5000
),
customer_mismatch_agg AS (
    SELECT
        c.c_customer_id,
        ca_bill.ca_city AS bill_city,
        ca_ship.ca_city AS ship_city,
        COUNT(*) AS mismatched_order_cnt,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(m.ws_net_profit) AS avg_net_profit,
        SUM(m.ws_net_profit) AS total_net_profit,
        MAX(m.ws_net_profit) AS max_net_profit,
        MIN(m.ws_net_profit) AS min_net_profit,
        PERCENT_RANK() OVER (ORDER BY SUM(m.ws_net_profit)) AS profit_percentile
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
    cm.total_net_paid,
    cm.avg_net_profit,
    cm.total_net_profit,
    cm.max_net_profit,
    cm.min_net_profit,
    CASE WHEN cm.profit_percentile > 0.9 THEN 'Top 10% Profit' ELSE 'Below Top 10%' END AS profit_tier
FROM customer_mismatch_agg cm
ORDER BY cm.total_net_profit DESC
LIMIT 20
