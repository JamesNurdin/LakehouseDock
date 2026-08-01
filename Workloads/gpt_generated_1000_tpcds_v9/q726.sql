WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        ws.ws_web_site_sk,
        web_site.web_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS num_orders,
        AVG(ws.ws_ext_wholesale_cost) AS avg_wholesale_cost,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rn_customer
    FROM
        customer c
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site
        ON ws.ws_web_site_sk = web_site.web_site_sk
    WHERE
        ca.ca_state IN ('CA', 'TX', 'NY')               -- filter 1: specific states
        AND ws.ws_ext_wholesale_cost > 2000.00          -- filter 2: high wholesale cost
        AND web_site.web_rec_end_date >= DATE '1999-01-01' -- filter 3: recent website records
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        ws.ws_web_site_sk,
        web_site.web_name
    HAVING
        SUM(ws.ws_net_paid) > 10000                     -- filter 4: significant spend
),
final_result AS (
    SELECT
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.ca_state,
        s.web_name,
        s.total_net_paid,
        s.num_orders,
        s.avg_wholesale_cost,
        s.rn_customer,
        SUM(s.total_net_paid) OVER (PARTITION BY s.ca_state) AS state_total_net_paid
    FROM
        sales_agg s
    WHERE
        EXISTS (
            SELECT 1
            FROM store_returns sr
            JOIN customer_address ca2
                ON sr.sr_addr_sk = ca2.ca_address_sk
            WHERE sr.sr_customer_sk = s.c_customer_sk
              AND ca2.ca_state = s.ca_state          -- semi‑join rule
              AND sr.sr_return_quantity > 0           -- filter inside semi‑join
        )
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    ca_state,
    web_name,
    total_net_paid,
    num_orders,
    avg_wholesale_cost,
    rn_customer,
    state_total_net_paid
FROM
    final_result
ORDER BY
    state_total_net_paid DESC,
    total_net_paid DESC
LIMIT 100
