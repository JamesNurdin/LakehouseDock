WITH sales_by_state AS (
    SELECT
        ca.ca_state,
        SUM(ss.ss_net_paid) AS total_amount,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS flag,
        'STORE_SALES' AS source
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY ca.ca_state
),
returns_by_state AS (
    SELECT
        ca.ca_state,
        SUM(sr.sr_net_loss) AS total_amount,
        CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'LOSS' ELSE 'NO_LOSS' END AS flag,
        'STORE_RETURNS' AS source
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY ca.ca_state
)
SELECT
    ca_state,
    total_amount,
    flag,
    source
FROM sales_by_state
UNION ALL
SELECT
    ca_state,
    total_amount,
    flag,
    source
FROM returns_by_state
ORDER BY total_amount DESC
LIMIT 100
