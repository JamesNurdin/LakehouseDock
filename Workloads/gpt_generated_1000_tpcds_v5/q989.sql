WITH sales_by_customer AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY cs.cs_bill_customer_sk
)
SELECT
    ca.ca_state,
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(sbc.total_profit) AS state_profit,
    SUM(sbc.total_sales) AS state_sales,
    REGEXP_EXTRACT(MIN(c.c_email_address), '@(.+)$', 1) AS sample_email_domain
FROM sales_by_customer sbc
JOIN customer c ON sbc.cust_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    REGEXP_LIKE(c.c_email_address, '.*@example\\.com$')
    AND ca.ca_city LIKE 'A%'
    AND ca.ca_state IN ('CA', 'NY', 'TX')
    AND EXISTS (
        SELECT 1
        FROM web_sales ws
        JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
        WHERE ws.ws_bill_customer_sk = c.c_customer_sk
          AND d2.d_year = 2020
          AND ws.ws_net_profit > 0
    )
GROUP BY ca.ca_state, ca.ca_city
HAVING SUM(sbc.total_profit) > 10000
ORDER BY state_profit DESC
LIMIT 100
