WITH sales_by_channel AS (
    -- Catalog sales aggregated by state
    SELECT
        ca.ca_state AS state,
        'catalog' AS channel,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
    UNION ALL
    -- Web sales aggregated by state
    SELECT
        ca.ca_state AS state,
        'web' AS channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
)
SELECT
    s.state,
    s.channel,
    s.total_sales,
    s.orders,
    CASE
        WHEN s.total_sales > (
            SELECT AVG(p.p_cost) * 1000
            FROM promotion p
            WHERE p.p_start_date_sk IN (
                SELECT d_date_sk
                FROM date_dim d2
                WHERE d2.d_year = 2001
            )
        ) THEN TRUE
        ELSE FALSE
    END AS high_sales_flag
FROM sales_by_channel s
WHERE s.state IN ('TX', 'CA', 'NY')
ORDER BY s.total_sales DESC
LIMIT 100
