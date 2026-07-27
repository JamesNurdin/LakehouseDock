WITH store_sales_agg AS (
    SELECT
        d.d_year AS year,
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, ca.ca_address_sk, ca.ca_city, ca.ca_state
),
catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS transactions
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT DISTINCT *
FROM (
    SELECT
        s.year,
        s.ca_address_sk,
        s.ca_city,
        s.ca_state,
        s.total_sales,
        s.transactions,
        'store' AS channel
    FROM store_sales_agg s
    WHERE EXISTS (
        SELECT 1 FROM reason r WHERE r.r_reason_id IS NOT NULL
    )
    UNION ALL
    SELECT
        c.year,
        c.ca_address_sk,
        c.ca_city,
        c.ca_state,
        c.total_sales,
        c.transactions,
        'catalog' AS channel
    FROM catalog_sales_agg c
    WHERE c.total_sales > 1000
) q
ORDER BY total_sales DESC
LIMIT 100
