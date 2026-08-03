WITH catalog_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        MAX(d.d_date) AS last_catalog_date,
        t.name_token
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    -- Expand the first name into an array (single element) and unnest it
    CROSS JOIN UNNEST(split(c.c_first_name, ',')) AS t(name_token)
    WHERE d.d_year = 2001
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, t.name_token
),
catalog_customers AS (
    SELECT DISTINCT c_customer_sk FROM catalog_agg
),
web_customers AS (
    SELECT DISTINCT ws.ws_bill_customer_sk AS c_customer_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
catalog_not_web AS (
    SELECT c.c_customer_sk
    FROM catalog_customers c
    EXCEPT
    SELECT w.c_customer_sk
    FROM web_customers w
)
SELECT
    ca.c_customer_sk,
    ca.c_first_name,
    ca.c_last_name,
    ca.catalog_sales_amount,
    ca.last_catalog_date,
    ca.name_token,
    (
        SELECT COALESCE(SUM(ws.ws_ext_sales_price), 0)
        FROM web_sales ws
        JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
        WHERE ws.ws_bill_customer_sk = ca.c_customer_sk
          AND d2.d_year = 2001
    ) AS web_sales_amount
FROM catalog_agg ca
JOIN catalog_not_web cnw ON ca.c_customer_sk = cnw.c_customer_sk
WHERE ca.c_preferred_cust_flag = 'Y'
ORDER BY ca.catalog_sales_amount DESC
LIMIT 100
