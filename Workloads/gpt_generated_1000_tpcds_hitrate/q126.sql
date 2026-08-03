WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ca.ca_city,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier = 'FEDEX'
      AND c.c_birth_month = 7
      AND ws.ws_ext_sales_price > 5000
      AND ca.ca_state = 'CA'
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ca.ca_city,
        sm.sm_ship_mode_id,
        sm.sm_carrier
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    c_email_address,
    ca_city,
    sm_ship_mode_id,
    sm_carrier,
    total_sales,
    total_profit,
    order_cnt,
    profit_flag,
    RANK() OVER (PARTITION BY sm_ship_mode_id ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY sales_rank
LIMIT 100
