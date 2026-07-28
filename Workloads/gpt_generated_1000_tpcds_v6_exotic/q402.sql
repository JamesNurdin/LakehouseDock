WITH bill_sales AS (
    SELECT
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        SUM(ws.ws_net_profit) AS total_profit,
        'billing' AS addr_role,
        SUM(ws.ws_net_profit) / (
            SELECT AVG(ws2.ws_net_profit)
            FROM web_sales ws2
        ) AS profit_vs_avg
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_ext_tax > 10
      AND ca.ca_zip = '48930'
    GROUP BY ca.ca_address_id, ca.ca_city, ca.ca_state
),
ship_sales AS (
    SELECT
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        SUM(ws.ws_net_profit) AS total_profit,
        'shipping' AS addr_role,
        SUM(ws.ws_net_profit) / (
            SELECT AVG(ws2.ws_net_profit)
            FROM web_sales ws2
        ) AS profit_vs_avg
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE ws.ws_sales_price BETWEEN 10 AND 20
      AND ca.ca_zip = '68252'
      AND EXISTS (
          SELECT 1
          FROM web_sales ws3
          WHERE ws3.ws_bill_customer_sk = ws.ws_bill_customer_sk
            AND ws3.ws_ext_tax > 15
      )
    GROUP BY ca.ca_address_id, ca.ca_city, ca.ca_state
)
SELECT *
FROM bill_sales
UNION ALL
SELECT *
FROM ship_sales
ORDER BY total_profit DESC
LIMIT 100
