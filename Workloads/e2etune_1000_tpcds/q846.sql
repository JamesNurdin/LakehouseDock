WITH store_channel AS (
    SELECT
        t.t_hour,
        ca.ca_state AS ca_state,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_year > 1950
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY t.t_hour, ca.ca_state
),
web_channel AS (
    SELECT
        t.t_hour,
        ca.ca_state AS ca_state,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_year > 1950
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY t.t_hour, ca.ca_state
),
combined AS (
    SELECT
        t_hour,
        ca_state,
        SUM(net_profit) AS total_net_profit,
        SUM(total_discount) AS total_discount,
        SUM(sales_cnt) AS total_sales_cnt
    FROM (
        SELECT * FROM store_channel
        UNION ALL
        SELECT * FROM web_channel
    ) u
    GROUP BY t_hour, ca_state
)
SELECT
    t_hour,
    ca_state,
    total_net_profit,
    total_discount / NULLIF(total_sales_cnt, 0) AS avg_discount_per_sale,
    total_sales_cnt,
    RANK() OVER (PARTITION BY t_hour ORDER BY total_net_profit DESC) AS state_rank
FROM combined
ORDER BY t_hour, state_rank
LIMIT 100
