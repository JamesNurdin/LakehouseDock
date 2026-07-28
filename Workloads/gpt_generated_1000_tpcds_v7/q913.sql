WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM
        tpcds.customer c
        JOIN tpcds.customer_address ca
            ON c.c_current_addr_sk = ca.ca_address_sk
        LEFT JOIN tpcds.catalog_sales cs
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        LEFT JOIN tpcds.web_sales ws
            ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1960 AND 1990
        AND ca.ca_state = 'CA'
        AND cs.cs_quantity > 5
        AND ws.ws_quantity > 3
        AND cs.cs_net_profit > 1000
        AND ws.ws_ext_tax BETWEEN 10 AND 500
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state
)
SELECT
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.ca_state,
    (cs.catalog_net_paid + cs.web_net_paid) AS total_net_paid,
    (cs.catalog_net_profit + cs.web_net_profit) AS total_net_profit,
    ROW_NUMBER() OVER (ORDER BY (cs.catalog_net_profit + cs.web_net_profit) DESC) AS profit_rank,
    RANK() OVER (ORDER BY (cs.catalog_net_paid + cs.web_net_paid) DESC) AS paid_rank,
    CASE
        WHEN cs.catalog_net_profit > cs.web_net_profit THEN 'Catalog higher'
        WHEN cs.catalog_net_profit < cs.web_net_profit THEN 'Web higher'
        ELSE 'Equal'
    END AS profit_source
FROM customer_sales cs
ORDER BY total_net_profit DESC
LIMIT 100
