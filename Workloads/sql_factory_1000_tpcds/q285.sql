WITH store_totals AS (
    SELECT ss_customer_sk AS cust_sk,
           SUM(ss_net_paid) AS store_net_paid
    FROM store_sales
    GROUP BY ss_customer_sk
),
web_totals AS (
    SELECT ws_bill_customer_sk AS cust_sk,
           SUM(ws_net_paid) AS web_net_paid
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
customer_agg AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           ca.ca_city,
           ca.ca_state,
           COALESCE(st.store_net_paid, 0) AS store_net_paid,
           COALESCE(wt.web_net_paid, 0) AS web_net_paid,
           COALESCE(st.store_net_paid, 0) + COALESCE(wt.web_net_paid, 0) AS total_net_paid
    FROM customer c
    LEFT JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN store_totals st
        ON st.cust_sk = c.c_customer_sk
    LEFT JOIN web_totals wt
        ON wt.cust_sk = c.c_customer_sk
)
SELECT
    c.c_customer_id,
    c.ca_city,
    c.ca_state,
    c.store_net_paid,
    c.web_net_paid,
    c.total_net_paid,
    CASE WHEN c.total_net_paid > 100000 THEN 'High Value' ELSE 'Regular' END AS customer_segment,
    RANK() OVER (ORDER BY c.total_net_paid DESC) AS revenue_rank
FROM customer_agg c
ORDER BY revenue_rank
LIMIT 10
