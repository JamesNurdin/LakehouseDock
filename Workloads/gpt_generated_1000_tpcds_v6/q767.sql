WITH recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
),
max_year_scalar AS (
    SELECT MAX(d_year) AS max_year FROM date_dim
)
SELECT DISTINCT
    state,
    CASE WHEN source = 'catalog' THEN 'Catalog Sales' ELSE 'Web Sales' END AS source_type,
    total_net_paid,
    total_profit,
    max_year
FROM (
    SELECT
        ca.ca_state AS state,
        'catalog' AS source,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        (SELECT max_year FROM max_year_scalar) AS max_year
    FROM catalog_sales cs
    JOIN recent_dates rd ON cs.cs_sold_date_sk = rd.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
    UNION ALL
    SELECT
        ca.ca_state AS state,
        'web' AS source,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_profit,
        (SELECT max_year FROM max_year_scalar) AS max_year
    FROM web_sales ws
    JOIN recent_dates rd ON ws.ws_sold_date_sk = rd.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
) AS combined
WHERE total_net_paid > 10000
ORDER BY total_net_paid DESC
LIMIT 100
