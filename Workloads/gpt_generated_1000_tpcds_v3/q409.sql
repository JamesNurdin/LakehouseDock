WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_addr_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state AS ca_state,
        d.d_year,
        cc.cc_name
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE
        regexp_like(c.c_first_name, '[AEIOUaeiou]{2}')
        AND ca.ca_city LIKE 'San%'
        AND d.d_year = 2002
)
SELECT
    ca_state,
    COUNT(DISTINCT cs_bill_customer_sk) AS num_customers,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(cs_net_profit) AS total_net_profit,
    MIN(CONCAT(c_first_name, ' ', c_last_name)) AS example_customer_name,
    MIN(REGEXP_EXTRACT(cc_name, '([A-Za-z]+) Center', 1)) AS call_center_type
FROM filtered_sales
GROUP BY ca_state
ORDER BY total_net_paid DESC
LIMIT 100
