WITH overall_sales AS (
    SELECT SUM(cs_net_profit) AS total_net_profit
    FROM catalog_sales
),
sales_by_city AS (
    SELECT
        ca.ca_city AS ca_city,
        ca.ca_state AS ca_state,
        'sales' AS activity_type,
        SUM(cs.cs_net_profit) AS total_amount,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        (SELECT total_net_profit FROM overall_sales) AS overall_net_profit
    FROM catalog_sales cs
    INNER JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_net_profit > 0
    GROUP BY ca.ca_city, ca.ca_state
),
returns_by_city AS (
    SELECT
        ca.ca_city AS ca_city,
        ca.ca_state AS ca_state,
        'returns' AS activity_type,
        SUM(wr.wr_net_loss) AS total_amount,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        (SELECT total_net_profit FROM overall_sales) AS overall_net_profit
    FROM web_returns wr
    INNER JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE wr.wr_net_loss > 0
    GROUP BY ca.ca_city, ca.ca_state
),
combined AS (
    SELECT * FROM sales_by_city
    UNION ALL
    SELECT * FROM returns_by_city
),
ranked AS (
    SELECT
        ca_city,
        ca_state,
        activity_type,
        total_amount,
        distinct_customers,
        overall_net_profit,
        ROW_NUMBER() OVER (PARTITION BY activity_type ORDER BY total_amount DESC) AS activity_rank
    FROM combined
)
SELECT
    ca_city,
    ca_state,
    activity_type,
    total_amount,
    distinct_customers,
    overall_net_profit,
    activity_rank
FROM ranked
WHERE total_amount > (SELECT total_net_profit * 0.05 FROM overall_sales)
ORDER BY activity_type, activity_rank
LIMIT 100
