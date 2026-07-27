/*
Goal: Identify high‑value customers by state and gender whose email address belongs to the example.com domain and whose login contains the substring "123". Summarize net paid sales, count distinct customers, and show a sample email domain.
*/
WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        c.c_login,
        ca.ca_state,
        cd.cd_gender,
        cs.cs_net_paid,
        REGEXP_EXTRACT(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain
    FROM catalog_sales cs
    INNER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    INNER JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE REGEXP_LIKE(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND c.c_login LIKE '%123%'
)
SELECT
    ca_state AS state,
    cd_gender AS gender,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_net_paid) AS avg_net_paid,
    MIN(email_domain) AS sample_email_domain
FROM customer_sales
GROUP BY ca_state, cd_gender
HAVING SUM(cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
