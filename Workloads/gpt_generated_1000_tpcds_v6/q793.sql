WITH sold_2022 AS (
    SELECT
        c.c_customer_id AS customer_id,
        d.d_year AS year,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2022
      AND c.c_birth_month = 5
    GROUP BY c.c_customer_id, d.d_year
),
shipped_2023 AS (
    SELECT
        c.c_customer_id AS customer_id,
        d.d_year AS year,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2023
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY c.c_customer_id, d.d_year
)
SELECT customer_id, year, total_profit
FROM sold_2022
UNION ALL
SELECT customer_id, year, total_profit
FROM shipped_2023
LIMIT 100
