WITH catalog_agg AS (
    SELECT
        ca.ca_state AS state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        'catalog' AS channel
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cs.cs_ext_sales_price > 1000
    GROUP BY ca.ca_state
),
web_agg AS (
    SELECT
        ca.ca_state AS state,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        'web' AS channel
    FROM tpcds.web_sales ws
    JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ws.ws_ext_sales_price > 1000
    GROUP BY ca.ca_state
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY total_sales DESC
LIMIT 50
