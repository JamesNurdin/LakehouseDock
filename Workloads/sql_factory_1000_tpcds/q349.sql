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
        ca_bill.ca_city AS bill_city,
        ca_ship.ca_city AS ship_city,
        SUM(m.ws_quantity) AS total_quantity,
        AVG(m.ws_net_profit) AS avg_net_profit,
        COUNT(*) AS mismatched_rows
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
    cm.total_quantity,
    cm.avg_net_profit,
    cm.mismatched_rows,
    CASE WHEN cm.total_quantity > 100 THEN 'Bulk Mismatch' ELSE 'Standard Mismatch' END AS quantity_category,
    RANK() OVER (PARTITION BY cm.bill_city ORDER BY cm.avg_net_profit DESC) AS city_profit_rank
FROM customer_mismatch_agg cm
ORDER BY city_profit_rank, cm.c_customer_id
LIMIT 15
