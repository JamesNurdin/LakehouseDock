WITH mismatched AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity
    FROM web_sales ws
    WHERE ws.ws_bill_addr_sk <> ws.ws_ship_addr_sk
      AND ws.ws_sold_date_sk >= 2450000
),
customer_mismatch_agg AS (
    SELECT
        c.c_customer_id,
        ca_bill.ca_country AS bill_country,
        ca_ship.ca_country AS ship_country,
        COUNT(*) AS mismatch_cnt,
        SUM(ws_quantity) AS total_qty,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_profit) AS avg_profit
    FROM mismatched m
    JOIN customer c ON m.cust_sk = c.c_customer_sk
    LEFT JOIN customer_address ca_bill ON m.ws_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship ON m.ws_ship_addr_sk = ca_ship.ca_address_sk
    GROUP BY c.c_customer_id, ca_bill.ca_country, ca_ship.ca_country
)
SELECT
    cm.c_customer_id,
    cm.bill_country,
    cm.ship_country,
    cm.mismatch_cnt,
    cm.total_qty,
    cm.total_profit,
    cm.avg_profit,
    CASE WHEN cm.bill_country = cm.ship_country THEN 'Domestic' ELSE 'International' END AS mismatch_type,
    DENSE_RANK() OVER (PARTITION BY cm.bill_country ORDER BY cm.total_profit DESC) AS country_profit_rank
FROM customer_mismatch_agg cm
ORDER BY cm.bill_country, country_profit_rank
LIMIT 12
