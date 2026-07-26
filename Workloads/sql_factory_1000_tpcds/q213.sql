WITH cust_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_net_paid) AS total_paid,
        COUNT(*) AS order_count
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    ca_city,
    ca_state,
    ca_zip,
    total_profit,
    total_paid,
    order_count,
    CASE
        WHEN total_profit > 100000 THEN 'High'
        WHEN total_profit BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM cust_sales
ORDER BY profit_rank
LIMIT 5
