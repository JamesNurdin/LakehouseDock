WITH sold_sales AS (
    SELECT
        c.c_customer_id AS customer_id,
        d_sold.d_year AS sales_year,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d_sold.d_year = 2001
      AND ws.ws_net_profit > (SELECT AVG(ws3.ws_net_profit) FROM web_sales ws3)
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY c.c_customer_id, d_sold.d_year
),
shipped_sales AS (
    SELECT
        c.c_customer_id AS customer_id,
        d_ship.d_year AS sales_year,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d_ship.d_year = 2001
      AND sm.sm_carrier = 'UPS'
      AND ws.ws_net_profit > (SELECT AVG(ws4.ws_net_profit) FROM web_sales ws4)
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY c.c_customer_id, d_ship.d_year
)
SELECT
    customer_id,
    sales_year,
    total_profit,
    order_cnt,
    'sold' AS source
FROM sold_sales
UNION ALL
SELECT
    customer_id,
    sales_year,
    total_profit,
    order_cnt,
    'shipped' AS source
FROM shipped_sales
ORDER BY total_profit DESC
LIMIT 100
