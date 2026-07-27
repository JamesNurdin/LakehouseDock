/* Goal: Identify top customers by net profit, combining billing‑address and shipping‑address perspectives, and rank them within each state. */
WITH billing_view AS (
    SELECT
        c.c_customer_id            AS customer_id,
        c.c_first_name             AS first_name,
        c.c_last_name              AS last_name,
        ca.ca_state                AS state,
        SUM(ws.ws_net_profit)      AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS avg_profit_all
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_year BETWEEN 1940 AND 1960
      AND ca.ca_zip LIKE '9%'
      AND EXISTS (
            SELECT 1
            FROM web_sales ws3
            WHERE ws3.ws_bill_customer_sk = c.c_customer_sk
              AND ws3.ws_net_paid_inc_ship > 5000
        )
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_state
    HAVING SUM(ws.ws_net_profit) > 1000
),
shipping_view AS (
    SELECT
        c.c_customer_id            AS customer_id,
        c.c_first_name             AS first_name,
        c.c_last_name              AS last_name,
        ca.ca_state                AS state,
        SUM(ws.ws_net_profit)      AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS avg_profit_all
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND ws.ws_ext_discount_amt > 500
      AND EXISTS (
            SELECT 1
            FROM web_sales ws3
            WHERE ws3.ws_ship_customer_sk = c.c_customer_sk
              AND ws3.ws_net_paid_inc_ship > 5000
        )
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_state
    HAVING SUM(ws.ws_net_profit) > 1000
),
combined_data AS (
    SELECT * FROM billing_view
    UNION ALL
    SELECT * FROM shipping_view
)
SELECT
    customer_id,
    first_name,
    last_name,
    state,
    total_net_profit,
    total_sales,
    avg_profit_all,
    RANK() OVER (PARTITION BY state ORDER BY total_net_profit DESC) AS profit_rank
FROM combined_data
ORDER BY total_net_profit DESC
LIMIT 100
